# Quick Start - GitHub Actions Deployment

## 🚀 One-Click Deployment Setup

### Step 1: Push to GitHub
```bash
git add .
git commit -m "Add GitHub Actions CI/CD"
git push origin main
```

### Step 2: Add AWS Secrets
1. Go to your GitHub repository
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Add these secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

### Step 3: Watch the Magic! ✨
- GitHub Actions will automatically deploy your Cloud CV
- Check the **Actions** tab to see progress
- Your website will be live in 15-20 minutes

## 🔄 How to Update Your CV

### Method 1: Edit Files Directly
1. Edit `frontend/index.html` with your new content
2. Commit and push:
   ```bash
   git add frontend/index.html
   git commit -m "Update CV content"
   git push origin main
   ```
3. GitHub Actions will automatically deploy the changes!

### Method 2: Edit via GitHub Web Interface
1. Go to your repository on GitHub
2. Click on `frontend/index.html`
3. Click the **pencil icon** to edit
4. Make your changes
5. Commit directly from GitHub
6. GitHub Actions will automatically deploy!

## 🎯 What Happens Automatically

1. **Code Push** → GitHub detects changes
2. **GitHub Actions** → Runs deployment workflow
3. **Terraform** → Updates AWS infrastructure
4. **S3 Upload** → Uploads your files
5. **CloudFront** → Invalidates cache
6. **Live Website**** → Your CV is updated!

## 🔍 Monitoring Your Deployment

### GitHub Actions Dashboard
- Repository → **Actions** tab
- Click on the latest workflow run
- View detailed logs and progress

### AWS Console
- **S3**: Check if files are uploaded
- **CloudFront**: Monitor distribution status
- **Lambda**: Check function logs
- **API Gateway**: Test endpoints

## 🚨 If Something Goes Wrong

1. **Check GitHub Actions logs** for error messages
2. **Verify AWS credentials** are set correctly
3. **Check AWS Console** for resource status
4. **Wait 15-20 minutes** for CloudFront to deploy

## 🎉 Success!

Your Cloud CV is now fully automated! Every time you push changes, your website will automatically update. This demonstrates:

- **Infrastructure as Code** (Terraform)
- **Continuous Integration/Deployment** (GitHub Actions)
- **Cloud Architecture** (AWS)
- **DevOps Best Practices**

Perfect for impressing SRE/DevOps recruiters! 🚀
