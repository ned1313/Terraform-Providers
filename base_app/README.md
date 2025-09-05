# Base Web App Configuration

This basic web app configuration will deploy a VPC in the us-west-2 region. During the *Terraform Providers* course you will make improvements to the configuration.

Before you begin making changes, you should make a copy of the `base_app` directory and make your changes in that copy. Run one of the following commands depending on your shell:

```bash
# Linux and Mac
cp ./base_app ./nacho_brigade
```

```powershell
# PowerShell
Copy-Item -Recurse .\base_app\ .\nacho_brigade
```

This base configuration **will not deploy successfully** as-is. You will need to make changes to fix the configuration before it will work properly.
