
resource "aws_iam_user" "admin_user" {
  name = "admin"
}

resource "aws_iam_user_policy_attachment" "admin_user_attach" {
  user       = aws_iam_user.admin_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_user_login_profile" "admin_login_profile" {
  user = aws_iam_user.admin_user.name
  depends_on = [aws_iam_user.admin_user]
}

