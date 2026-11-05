# Test Pipeline Run

This is a test branch to verify the GitLab CI/CD pipeline is working correctly.

## Pipeline Testing

When you push this branch, the GitLab pipeline should:
1. ✓ Run version check
2. ✓ Run validation (format + terraform validate)
3. ✓ Generate terraform plan
4. NOT run apply (feature branches skip apply/destroy stages)

View the pipeline at: https://gitlab.com/cupando/team-alpha-compute/-/pipelines

