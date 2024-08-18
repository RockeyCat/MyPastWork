resource "aws_codepipeline" "app-codepipeline" {
  name = "app-codepipeline"
  role_arn = aws_iam_role.codepipeline-role.arn

  artifact_store {
    location = aws_s3_bucket.aws-s3-bucket.bucket
    type = "S3"

    encryption_key {
      id = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }


  stage {

    name = "Source"
    action {
        name = "Source"
        category = "Source"
        owner = "AWS"
        provider = "CodeStarSourceConnection"
        version = "1"
        output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn = aws_codestarconnections_connection.app-codestar.arn
        FullRepositoryID = var.FullRepositoryID
        BranchName = "master"
      }
    }
  }

  stage {

    name = "Build"
    action {
        name = "Build"
        category = "Build"
        owner = "AWS"
        provider = "CodeBuild"
        input_artifacts = [ "source_output" ]
        output_artifacts = ["build_output"]
        version = "1"
      configuration = {
        ProjectName = "test"
      }
    }
  }

  stage {
    name = "Deploy"
    action {
        name = "Deploy"
        category = "Deploy"
        owner = "AWS"
        provider = "CloudFormation"
      input_artifacts =  ["build_output"]
      version = "1"
      configuration = {
        ActionMode = "CAPABILITY_AUTO_EXPAND, CAPABILITY_IAM"
        outputFileName = "CreateStackOutput.json"
        StackName = "MyStack"
        TemplatePath = "build_output::sam-templated.yaml"
      }
    }
  }


}


resource "aws_codestarconnections_connection" "app-codestar" {
  name          = "example-connection"
  provider_type = "GitHub"
}