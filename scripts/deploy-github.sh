#!/bin/bash

# Taskflow Backend - GitHub Actions Deployment Helper
# This script helps trigger GitHub Actions deployments and check status

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
REPO_OWNER=""
REPO_NAME=""
ENVIRONMENT="dev"
GITHUB_TOKEN=""

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] COMMAND"
    echo ""
    echo "Commands:"
    echo "  deploy     Trigger deployment workflow"
    echo "  status     Check deployment status"
    echo "  logs       View deployment logs"
    echo "  cancel     Cancel running workflows"
    echo ""
    echo "Options:"
    echo "  -o, --owner      GitHub repository owner [required]"
    echo "  -r, --repo       GitHub repository name [required]"
    echo "  -e, --env        Environment (dev, staging, prod) [default: dev]"
    echo "  -t, --token      GitHub token [required]"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --owner your-org --repo taskflow-backend --env dev --token ghp_xxx deploy"
    echo "  $0 --owner your-org --repo taskflow-backend --env staging --token ghp_xxx status"
    echo ""
}

# Function to check dependencies
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install it first."
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi
}

# Function to trigger deployment
trigger_deployment() {
    print_info "Triggering deployment to $ENVIRONMENT environment..."
    
    local workflow_id
    workflow_id=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows" | \
        jq -r '.workflows[] | select(.name == "CI/CD Pipeline") | .id')
    
    if [[ "$workflow_id" == "null" || -z "$workflow_id" ]]; then
        print_error "CI/CD Pipeline workflow not found"
        exit 1
    fi
    
    local response
    response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/workflows/$workflow_id/dispatches" \
        -d "{\"ref\":\"main\",\"inputs\":{\"environment\":\"$ENVIRONMENT\",\"force_deploy\":true}}")
    
    if [[ -z "$response" ]]; then
        print_success "Deployment triggered successfully!"
        print_info "Check the status with: $0 --owner $REPO_OWNER --repo $REPO_NAME --env $ENVIRONMENT --token $GITHUB_TOKEN status"
    else
        print_error "Failed to trigger deployment: $response"
        exit 1
    fi
}

# Function to check deployment status
check_status() {
    print_info "Checking deployment status for $ENVIRONMENT environment..."
    
    local workflow_runs
    workflow_runs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs?per_page=10")
    
    local latest_run
    latest_run=$(echo "$workflow_runs" | jq -r '.workflow_runs[0]')
    
    local status
    status=$(echo "$latest_run" | jq -r '.status')
    local conclusion
    conclusion=$(echo "$latest_run" | jq -r '.conclusion')
    local html_url
    html_url=$(echo "$latest_run" | jq -r '.html_url')
    local created_at
    created_at=$(echo "$latest_run" | jq -r '.created_at')
    
    print_info "Latest workflow run:"
    echo "  Status: $status"
    echo "  Conclusion: $conclusion"
    echo "  Created: $created_at"
    echo "  URL: $html_url"
    
    if [[ "$status" == "completed" ]]; then
        if [[ "$conclusion" == "success" ]]; then
            print_success "Deployment completed successfully!"
        else
            print_error "Deployment failed!"
        fi
    elif [[ "$status" == "in_progress" ]]; then
        print_warning "Deployment is still running..."
    else
        print_info "Deployment status: $status"
    fi
}

# Function to view logs
view_logs() {
    print_info "Getting logs for latest $ENVIRONMENT deployment..."
    
    local workflow_runs
    workflow_runs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs?per_page=5")
    
    local latest_run_id
    latest_run_id=$(echo "$workflow_runs" | jq -r '.workflow_runs[0].id')
    
    if [[ "$latest_run_id" == "null" || -z "$latest_run_id" ]]; then
        print_error "No workflow runs found"
        exit 1
    fi
    
    print_info "Latest workflow run ID: $latest_run_id"
    print_info "View logs at: https://github.com/$REPO_OWNER/$REPO_NAME/actions/runs/$latest_run_id"
    
    # Get jobs for the workflow run
    local jobs
    jobs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$latest_run_id/jobs")
    
    echo ""
    print_info "Available jobs:"
    echo "$jobs" | jq -r '.jobs[] | "  \(.name): \(.status) - \(.conclusion // "N/A")"'
}

# Function to cancel workflows
cancel_workflows() {
    print_info "Cancelling running workflows..."
    
    local workflow_runs
    workflow_runs=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs?status=in_progress&per_page=10")
    
    local running_runs
    running_runs=$(echo "$workflow_runs" | jq -r '.workflow_runs[] | select(.status == "in_progress") | .id')
    
    if [[ -z "$running_runs" ]]; then
        print_info "No running workflows found"
        return 0
    fi
    
    echo "$running_runs" | while read -r run_id; do
        if [[ -n "$run_id" && "$run_id" != "null" ]]; then
            print_info "Cancelling workflow run: $run_id"
            curl -s -X POST \
                -H "Authorization: token $GITHUB_TOKEN" \
                -H "Accept: application/vnd.github.v3+json" \
                "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/actions/runs/$run_id/cancel"
        fi
    done
    
    print_success "Workflow cancellation requests sent"
}

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--owner)
            REPO_OWNER="$2"
            shift 2
            ;;
        -r|--repo)
            REPO_NAME="$2"
            shift 2
            ;;
        -e|--env)
            ENVIRONMENT="$2"
            shift 2
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        deploy|status|logs|cancel)
            COMMAND="$1"
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" || -z "$GITHUB_TOKEN" || -z "$COMMAND" ]]; then
    print_error "Missing required parameters"
    show_usage
    exit 1
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT. Must be dev, staging, or prod."
    exit 1
fi

# Check dependencies
check_dependencies

# Execute command
case $COMMAND in
    deploy)
        trigger_deployment
        ;;
    status)
        check_status
        ;;
    logs)
        view_logs
        ;;
    cancel)
        cancel_workflows
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac
