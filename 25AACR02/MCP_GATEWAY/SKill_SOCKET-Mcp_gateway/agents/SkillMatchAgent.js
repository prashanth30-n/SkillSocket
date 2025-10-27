const { findComplementaryUsers, testConnection } = require('../tools/dbTool');

class SkillMatchAgent {
  constructor(llmClient, toolRegistry) {
    this.llmClient = llmClient;
  }

  async run(query) {
    console.log(`SkillMatch Agent started with query: "${query}"`);
    
    try {
      // Test backend API connection first
      console.log('🔌 Testing backend API connection...');
      const connectionTest = await testConnection();
      if (!connectionTest.success) {
        throw new Error(`Backend API connection failed: ${connectionTest.error}`);
      }
      console.log(`✅ Backend API is accessible!`);
      
      // Extract skills from the query using LLM with better prompting
      const extractionPrompt = `
        Analyze this user query and extract the skills they need to learn and the skills they can offer to teach others.
        Return ONLY a valid JSON object with two arrays.
        
        Query: "${query}"
        
        Instructions:
        - "skillsRequired" = skills the user wants to learn, need, or is looking for
        - "skillsOffered" = skills the user can teach, offer, knows, or is good at
        - Look for phrases like: "I offer", "I can teach", "I know", "I'm good at", "I have experience in" (for offered skills)
        - Look for phrases like: "I need", "I want to learn", "I'm looking for", "help me with", "teach me" (for required skills)
        - Use common skill names like "JavaScript", "Python", "React", "Flutter", "Java", "Machine Learning", "Node.js", "CSS", "HTML", etc.
        - If user mentions wanting to exchange or trade skills, extract both sides appropriately
        - If no specific skills are mentioned, return empty arrays
        
        Example formats:
        Query: "I offer Flutter and need Java" → {"skillsRequired": ["Java"], "skillsOffered": ["Flutter"]}
        Query: "I can teach Python, want to learn React" → {"skillsRequired": ["React"], "skillsOffered": ["Python"]}
        Query: "Help me find users" → {"skillsRequired": [], "skillsOffered": []}
        
        Return only the JSON, no explanation:
      `;
      
      const extractionResult = await this.llmClient.generateText(extractionPrompt, 0.1);
      console.log("Raw LLM extraction result:", extractionResult);
      
      // Better JSON parsing with multiple attempts
      let skills;
      try {
        // First try: direct JSON parse
        skills = JSON.parse(extractionResult.trim());
      } catch (e1) {
        try {
          // Second try: extract JSON from text
          const jsonMatch = extractionResult.match(/\{[\s\S]*\}/);
          if (jsonMatch) {
            skills = JSON.parse(jsonMatch[0]);
          } else {
            throw new Error("No JSON found in response");
          }
        } catch (e2) {
          // Fallback: manual extraction
          console.log("JSON parsing failed, using fallback extraction");
          skills = this.extractSkillsFallback(query);
        }
      }
      
      // Validate and clean skills
      if (!skills.skillsRequired) skills.skillsRequired = [];
      if (!skills.skillsOffered) skills.skillsOffered = [];
      
      console.log("Extracted skills:", skills);
      
      // Find complementary users from database with timeout
      console.log('Searching for matching users...');
      const matchedUsers = await Promise.race([
        findComplementaryUsers(skills.skillsRequired, skills.skillsOffered),
        new Promise((_, reject) => setTimeout(() => reject(new Error('User search timeout after 8 seconds')), 8000))
      ]);
      console.log(`Found ${matchedUsers.length} matching users`);
      
      // Generate a response using the LLM
      let response;
      
      if (matchedUsers.length > 0) {
        const usersData = matchedUsers.map((user, index) => 
          `${index + 1}. **${user.name || user.firstName + ' ' + user.lastName || 'User'}** (${user.email})
   • 💡 **Offers**: ${user.skillsOffered.length > 0 ? user.skillsOffered.join(', ') : 'Not specified'}
   • 🎯 **Needs**: ${user.skillsRequired.length > 0 ? user.skillsRequired.join(', ') : 'Not specified'}
   • 📍 **Location**: ${user.location || 'Not specified'}`
        ).join('\n\n');
        
        response = `🎯 **Perfect! I found ${matchedUsers.length} user${matchedUsers.length > 1 ? 's' : ''} with complementary skills:**

**Your Profile:**
• 📚 **Want to learn**: ${skills.skillsRequired.join(', ') || 'Not specified'}
• 💡 **Can teach**: ${skills.skillsOffered.join(', ') || 'Not specified'}

**Recommended Connections:**

${usersData}

💡 **Why these matches work:**
These users offer skills you want to learn and need skills you can teach - creating perfect skill exchange opportunities!

**Next Steps:**
1. Reach out to these users through the platform
2. Propose a skill exchange arrangement
3. Set up learning sessions or mentorship
4. Build lasting professional connections`;
      } else {
        response = `🔍 **No exact matches found, but don't worry!**

**Your Skills Profile:**
• 📚 **Want to learn**: ${skills.skillsRequired.join(', ') || 'Not specified'}
• 💡 **Can teach**: ${skills.skillsOffered.join(', ') || 'Not specified'}

**Suggestions to find skill partners:**

1. **Broaden your search**: Consider related skills (e.g., if you want React, look for JavaScript experts)
2. **Update your profile**: Make sure your skills are clearly listed
3. **Be proactive**: Reach out to users with similar interests
4. **Join communities**: Look for study groups or skill-sharing circles
5. **Check back later**: New users join regularly!

**Alternative approach**: Consider offering your skills in exchange for general mentorship or project collaboration opportunities.`;
      }
      
      return {
        matches: matchedUsers,
        response: response,
        query: {
          skillsRequired: skills.skillsRequired,
          skillsOffered: skills.skillsOffered
        },
        matchCount: matchedUsers.length
      };
    } catch (error) {
      console.error("Error in SkillMatch Agent:", error);
      
      // Provide more specific error messages based on error type
      let errorMessage = error.message;
      let suggestions = [
        "1. Check your internet connection",
        "2. Try again in a few moments",
        "3. Use simpler skill names like 'JavaScript', 'Python', 'React'"
      ];
      
      if (error.message.includes('timeout') || error.message.includes('buffering')) {
        errorMessage = "Database connection timed out";
        suggestions = [
          "1. The database server might be slow or unavailable",
          "2. Check your internet connection",
          "3. Try again in a few minutes",
          "4. Contact support if the issue persists"
        ];
      } else if (error.message.includes('connection')) {
        errorMessage = "Could not connect to the database";
        suggestions = [
          "1. Check if the database service is running",
          "2. Verify your internet connection",
          "3. Try again later"
        ];
      }
      
      return {
        error: error.message,
        response: `❌ **Database Connection Issue**

**Problem**: ${errorMessage}

**What you can try:**
${suggestions.map(s => `• ${s}`).join('\n')}

**Alternative**: While we fix this, try asking general questions about skills or learning paths!`,
        matches: [],
        matchCount: 0
      };
    }
  }

  // Fallback method to extract skills when JSON parsing fails
  extractSkillsFallback(query) {
    const lowerQuery = query.toLowerCase();
    const commonSkills = [
      'javascript', 'python', 'java', 'react', 'flutter', 'dart', 'node.js', 'nodejs',
      'angular', 'vue', 'typescript', 'c++', 'c#', 'php', 'ruby', 'go', 'kotlin',
      'swift', 'html', 'css', 'sql', 'mongodb', 'mysql', 'postgresql', 'docker',
      'kubernetes', 'aws', 'azure', 'git', 'linux', 'machine learning', 'ai',
      'data science', 'spring boot', 'django', 'express', 'laravel'
    ];

    const skillsRequired = [];
    const skillsOffered = [];

    // Look for "learn", "need", "want" patterns
    const learnPatterns = ['learn', 'need', 'want to learn', 'studying', 'learning'];
    const teachPatterns = ['teach', 'offer', 'know', 'expert in', 'can help with'];

    learnPatterns.forEach(pattern => {
      if (lowerQuery.includes(pattern)) {
        commonSkills.forEach(skill => {
          if (lowerQuery.includes(skill) && !skillsRequired.includes(skill)) {
            skillsRequired.push(skill);
          }
        });
      }
    });

    teachPatterns.forEach(pattern => {
      if (lowerQuery.includes(pattern)) {
        commonSkills.forEach(skill => {
          if (lowerQuery.includes(skill) && !skillsOffered.includes(skill)) {
            skillsOffered.push(skill);
          }
        });
      }
    });

    // Default skills if none found
    if (skillsRequired.length === 0 && skillsOffered.length === 0) {
      if (lowerQuery.includes('flutter')) skillsRequired.push('Flutter');
      if (lowerQuery.includes('java')) skillsOffered.push('Java');
    }

    return { skillsRequired, skillsOffered };
  }
}

module.exports = SkillMatchAgent;