class PerplexityAgent{
    constructor(llmClient,toolRegistry){
        this.llmClient=llmClient;
        this.websearchTool=toolRegistry.get('web_search');
    
    }
    async run(query){
        const searchResults=await this.websearchTool(query);
        if (!searchResults?.results?.length) {
            return { answer: "Sorry, I couldn't find relevant information online.", sources: [] };
        }
         const context = searchResults.results.map((res, i) => `Source [${i + 1}]: ${res.content} (URL: ${res.url})`).join('\n\n');
        const prompt = `User's question: "${query}"\n\nContext:\n${context}\n\nBased only on the provided context, write a comprehensive answer. Cite sources using the format [1], [2], etc.`;
        const answer = await this.llmClient.generateText(prompt);
        const sources = searchResults.results.map(res => ({ url: res.url, title: res.title }));
        return { answer, sources: [...new Map(sources.map(item => [item.url, item])).values()] };
    }
}
module.exports=PerplexityAgent;