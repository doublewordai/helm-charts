# Contributing to the Inference Stack Helm Chart

This document provides guidelines for contributing to the Inference Stack Helm chart.

## Development Environment

### Prerequisites

- Helm v3.x
- Kubernetes cluster (local or remote)
- Git

## Development Workflow

### Getting Started

1. Clone the repository: `git clone <repository-url>`
2. Create a feature branch: `git checkout -b feat-my-feature`

### Making Changes

1. Modify chart files in the appropriate directories:
   - Update `values.yaml` for new configuration options
   - Add or modify templates in the `templates/` directory
   - Update `Chart.yaml` if changing dependencies or versions

2. Follow existing code style conventions:
   - 2-space indentation in YAML files
   - camelCase for configuration keys in Helm values
   - snake_case for underlying container configuration
   - Include consistent name prefixes with release name

### Testing Your Changes

1. Lint the chart to verify syntax:

   ```bash
   helm lint .
   ```

2. Validate template rendering:

   ```bash
   helm template . --debug
   ```

3. Run unit tests:

   ```bash
   helm unittest .
   ```

4. To run specific tests:

   ```bash
   helm unittest -f tests/gateway_test.yaml .
   ```

5. Write new tests for added functionality in the `tests/` directory

### Creating Pull Requests

1. Commit your changes with a descriptive message
2. Push your branch: `git push origin feat-my-feature`
3. Create a pull request against the main branch

## Testing Guidelines

### Unit Tests

- Each new feature should include unit tests
- Tests should be placed in the `tests/` directory
- Use assertion-based tests with equality and regex matching
- Organize test files by component
- Use documentSelector to target specific resources
- Include value overrides for testing specific configurations

### Test Values

- Store test value overrides in `tests/values/` directory
- Create snapshot tests for complex templates

## Additional Resources

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Unit Testing Plugin](https://github.com/quintush/helm-unittest)
