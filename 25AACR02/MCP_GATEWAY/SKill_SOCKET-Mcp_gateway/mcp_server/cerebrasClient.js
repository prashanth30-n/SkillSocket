const axios = require('axios');

class CerebrasClient {
    constructor() {
        if (!process.env.CEREBRAS_API_KEY) {
            throw new Error("CEREBRAS_API_KEY is not set in the environment variables.");
        }
        this.client = axios.create({
            baseURL: 'https://api.cerebras.ai/v1',
            headers: {
                'Authorization': `Bearer ${process.env.CEREBRAS_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });
    }

    
    async generateText(prompt, temperature = 0.5) {
        try {
            const payload = {
                model: 'llama3.1-8b', // You can change this to other supported models
                messages: [{ role: 'user', content: prompt }],
                temperature,
                max_tokens: 2000,
            };
            const response = await this.client.post('/chat/completions', payload);
            return response.data.choices[0].message.content;
        } catch (error) {
            console.error('Cerebras API Error:', error.response ? error.response.data : error.message);
            throw new Error('Failed to generate text from Cerebras API.');
        }
    }
}

module.exports = CerebrasClient;
