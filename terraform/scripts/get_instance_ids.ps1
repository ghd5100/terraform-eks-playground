# param()

# $json = aws ec2 describe-instances --filters "Name=tag:Name,Values=default" "Name=instance-state-name,Values=running" --region ap-northeast-2 | ConvertFrom-Json

# $instanceIds = $json.Reservations | ForEach-Object {
#     $_.Instances | ForEach-Object {
#         $_.InstanceId
#     }
# } | Select-Object -Unique

# # 배열이 아니라면 배열로 감싸기
# if ($instanceIds -isnot [System.Array]) {
#     $instanceIds = @($instanceIds)
# }

# @{
#     ids = $instanceIds
# } | ConvertTo-Json -Compress

param()

$json = aws ec2 describe-instances --filters "Name=tag:Name,Values=default" "Name=instance-state-name,Values=running" --region ap-northeast-2 | ConvertFrom-Json

$instanceIds = $json.Reservations | ForEach-Object {
    $_.Instances | ForEach-Object {
        $_.InstanceId
    }
} | Select-Object -Unique

# 배열이 아니라면 배열로 감싸기
if ($instanceIds -isnot [System.Array]) {
    $instanceIds = @($instanceIds)
}

# 배열을 쉼표로 연결한 문자열로 변환
$idsString = $instanceIds -join ","

# JSON 객체로 출력
@{
    ids = $idsString
} | ConvertTo-Json -Compress
