# AlboradaIT Project Cookbooks

This repository contains standardized project creation cookbooks for the AlboradaIT development team.

## What are Cookbooks?

Cookbooks are step-by-step guides that include:
- Project setup instructions
- Infrastructure configuration
- Code templates and stubs
- Best practices and conventions

## How to Use

1. **Choose your cookbook** based on project type
2. **Reference the cookbook URL** when asking AI agents to create projects
3. **Follow the step-by-step instructions** in the cookbook
4. **Copy embedded templates** directly from the markdown

## Available Cookbooks

- [Laravel Web Application](./laravel-web-app.md) - Standard Laravel web application with Docker
- [Laravel API](./laravel-api.md) - API-only Laravel project with microservice setup

## Team Workflow

### For Team Members
```bash
# When requesting a new project from an AI agent:
"Create a new Laravel web application following the AlboradaIT cookbook at:
https://github.com/AlboradaIT/project-cookbooks/blob/main/laravel-web-app.md"
```

### For AI Agents
The cookbooks contain all necessary:
- Step-by-step instructions
- File templates and configurations
- Validation steps
- Best practices

## Updating Cookbooks

- Cookbooks evolve based on team feedback
- Submit PRs to improve existing cookbooks
- Add new cookbooks for new project types

## Organization Standards

All projects created using these cookbooks will have:
- Consistent Docker setups
- Standardized Traefik integration
- Proper copilot-instructions for AI assistance
- Validated infrastructure before development

---

**AlboradaIT Development Team**  
*Standardizing excellence, one project at a time.*
