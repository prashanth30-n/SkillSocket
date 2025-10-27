const axios = require('axios');

async function webSearch(query) {
    if (!process.env.TAVILY_API_KEY) {
        throw new Error("TAVILY_API_KEY is not set in environment variables");
    }
    try {
        const response = await axios.post('https://api.tavily.com/search', {
            api_key: process.env.TAVILY_API_KEY,
            query: query,
            search_depth: 'advanced',
            max_results: 5
        });
        return response.data;
    } catch (error) {
        throw new Error(`Web search failed. Error: ${error.message}`);
    }
}

module.exports = { webSearch };