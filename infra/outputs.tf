output "versions_bucket" { value = aws_s3_bucket.eb_versions.bucket }
output "app_name"        { value = aws_elastic_beanstalk_application.app.name }
output "env_name"        { value = aws_elastic_beanstalk_environment.env.name }
output "env_url"         { value = aws_elastic_beanstalk_environment.env.endpoint_url }
