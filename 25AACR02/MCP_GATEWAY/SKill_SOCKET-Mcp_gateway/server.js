require('dotenv').config();
const express = require('express');
const cors = require('cors');
const CerebrasClient = require('./mcp_server/cerebrasClient');
const ToolRegistry = require('./mcp_server/toolRegistry');
const MCPRouter = require('./mcp_server/router');
const PerplexityAgent = require('./agents/perplexityAgent');
const RoadmapAgent = require('./agents/RoadmapAgent');
const SkillMatchAgent = require('./agents/SkillMatchAgent');

const app = express();
const port = process.env.PORT || 8000;

app.use(cors());
app.use(express.json());

const llmClient = new CerebrasClient();
const toolRegistry = new ToolRegistry();
const perplexityAgent = new PerplexityAgent(llmClient, toolRegistry);
const roadmapAgent = new RoadmapAgent(llmClient, toolRegistry);
const skillMatchAgent = new SkillMatchAgent(llmClient, toolRegistry);
const mcpRouter = new MCPRouter(llmClient, {
    perplexity: perplexityAgent,
    roadmap: roadmapAgent,
    skillmatch: skillMatchAgent
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ 
        status: 'healthy',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        service: 'Skill Socket MCP Gateway'
    });
});

app.post('/mcp/invoke', async (req, res) => {
    const { query } = req.body;
    if (!query) return res.status(400).json({ error: 'A "query" is required.' });
    try {
        const result = await mcpRouter.route(query);
        res.json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.listen(port, () => {
    console.log(`Skill Socket MCP Server listening at http://localhost:${port}`);
});