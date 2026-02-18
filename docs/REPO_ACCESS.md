# Repository Access Information

This document outlines the capabilities and limitations regarding repository access for the AI assistant.

## Current Repository
The AI assistant has direct access to the repository where the task is initiated (`vmware-scripts`).

## Other Repositories
### Public Repositories
The AI assistant can access public repositories using standard git commands (e.g., `git clone`) if provided with the repository URL. This allows inspection and read-only access.

### Private Repositories
Access to private repositories requires authentication credentials (SSH keys or tokens). Due to security constraints and the isolated nature of the environment, the AI assistant cannot securely handle or store these credentials. Therefore, access to private repositories is not supported unless explicitly configured by the platform administrator.

## Recommendations
- If you need the AI assistant to work on another repository, please initiate a new task within that repository.
- If you need to reference code from another public repository, please provide the URL.
