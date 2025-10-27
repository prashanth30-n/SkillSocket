class RoadmapAgent {
    constructor(llmClient, toolRegistry) {
        this.llmClient=llmClient;
        this.websearchTool=toolRegistry.get('web_search');
    }

    async run(topic){
        console.log(`Roadmap Agent started for topic: "${topic}"`);
        const searchResults = await this.websearchTool(`learning path and key concepts for ${topic}`);
        const context = searchResults.results.map(res => `Source: ${res.content}`).join('\n\n');
        const prompt = `Topic: "Learn ${topic}"\n\nContext:\n${context}\n\nBased on the context, generate a detailed, step-by-step learning roadmap in Markdown. Include stages (Beginner, Intermediate, Advanced) with key concepts and project ideas.`;
        const roadmap = await this.llmClient.generateText(prompt, 0.7);
        return { roadmap };
}
}
module.exports=RoadmapAgent;