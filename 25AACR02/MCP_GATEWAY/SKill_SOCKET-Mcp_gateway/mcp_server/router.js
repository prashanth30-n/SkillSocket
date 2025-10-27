class MCPRouter {
    constructor(llmClient, agents) {
        this.llmClient = llmClient;
        this.agents = agents;
    }
    async route(query) {
        console.log(`MCP Router received query: "${query}"`);
        const agentDescriptions = `
- perplexity: Answers specific questions using web search. Use for facts, definitions, current events, or general knowledge questions.
- roadmap: Generates a detailed learning plan for a topic. Use for "how to learn X", "roadmap for Y", "study plan", "learning path".
- skillmatch: Finds users with complementary skills for skill exchange. Use for ANY query mentioning skills like "I offer X", "I need Y", "I can teach Z", "I want to learn W", "find users", "match me", "skill exchange", "connect me", "users who have", "people who need", or any combination of offering and learning skills.`;
        const prompt = `You are an intelligent router. Select the best agent for the user's query.\n\nAvailable agents:\n${agentDescriptions}\n\nUser query: "${query}"\n\nRespond with a JSON object containing "agent" (the agent's name) and "input" (the query for that agent).`;
        const responseStr = await this.llmClient.generateText(prompt, 0.1);
        try {
            const jsonMatch = responseStr.match(/\{[\s\S]*\}/);
            if (!jsonMatch) throw new Error("LLM did not return valid JSON for routing.");
            const decision = JSON.parse(jsonMatch[0]);
            console.log('AI routing decision:', decision);
            const agentToRun = this.agents[decision.agent];
            if (!agentToRun) throw new Error(`AI chose an invalid agent: ${decision.agent}`);
            const result = await agentToRun.run(decision.input);
            return { agentUsed: decision.agent, result };
        } catch (error) {
            console.error("MCP Routing failed:", error, "Falling back to perplexity agent.");
            const fallbackResult = await this.agents.perplexity.run(query);
            return { agentUsed: 'perplexity (fallback)', result: fallbackResult };
        }
    }
}
module.exports = MCPRouter;