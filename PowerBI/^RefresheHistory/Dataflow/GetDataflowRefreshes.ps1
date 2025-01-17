<# 
    処理概要:
        Power BI データフローの更新履歴をjsonに出力するスクリプトです。

    input:
        ./DataflowList.csv：更新履歴を取得したいワークスペース名とデータフローをカンマ(",")区切りで記載します。
        例: 
            workspaceName,dataflowName
            workspace001,dataflow101
            workspace001,dataflow102
            workspace002,dataflow201
            …

    output:
        ./GetDataflowRefreshes.log:スクリプトの実行ログです。
        ./dfRefreshes/yyyymmdd_dfRefreshes.json
#>

<#
    ファイル出力処理
    出力先に同一ファイル名が存在する場合は追記処理を行います。
    $filePath:出力先ファイルパス
    $fileData:出力ファイルデータ
#>
function Add_file($filePath, $fileData) {
    # ファイル追記処理
    $fileData | Out-File -Encoding utf8 -FilePath $filePath -Append
}


# スクリプト実行ディレクトリパス取得
$path = Split-Path -Parent $MyInvocation.MyCommand.$path
Set-Location $path

# ログファイル設定
$log_file = $path + "\GetDataflowRefreshes.log"


# 処理開始
Add_file ($log_file) ("Start---------------------------------------")
Add_file ($log_file) (Get-Date)

# アウトプットファイル設定
$date = Get-Date -format "yyyymmdd"
$date_str = $date.ToString()

# アウトプットファイルパス設定
$output_dir = $path + "\dfRefreshes\"
$output_FilePath = $output_dir + $date_str + "_dfRefreshes.json"

# アウトプットフォルダ存在チェック
if ( -not (Test-Path $output_dir)) {
    # 処理結果出力フォルダ作成
    New-Item $output_dir -ItemType Directory
}

# ワークスペース名とデータフロー名取得
$input_file = $path + "\DataflowList.csv"
$csvData = Import-Csv -Path $input_file

try {

    # Power BI ログイン
    Connect-PowerBIServiceAccount

    # 出力データ編集用
    $editList = New-Object System.Collections.ArrayList

    # csvファイルの行数分、繰り返す
    foreach ( $item in $csvData ) {

        Add_file ($log_file) ("更新履歴の取得開始 -----------------")
        Add_file ($log_file) ("ワークスペース名：" + $item.workspaceName)
        Add_file ($log_file) ("データフロー名：" + $item.dataflowName)
        
        # ワークスペース情報取得
        $workspace = Get-PowerBIWorkspace -Name $item.workspaceName

        # データフロー名からデータフローIDを取得する
        $dfInfo = Get-PowerBIDataflow -WorkspaceId $workspace.Id -Name $item.dataflowName

        # Rest Api用のURL作成
        $restUrl = "https://api.powerbi.com/v1.0/myorg/groups/" + $workspace.Id + "/dataflows/" + $dfinfo.id + "/transactions"

        # データフロー更新履歴を取得する
        $dfRefreshes = Invoke-PowerBIRestMethod -Url $restUrl -Method Get

        # jsonコンバート
        $jsonRefreshes = ConvertFrom-Json $dfRefreshes

        # 出力用に編集
        forEach($item in $jsonRefreshes.value){
            $data = @{
                "workspaceName" = $workspace.Name
                "requestId" = $item.id
                "dataflowName" = $dfInfo.Name
                "refreshType" = $item.refreshType
                # 更新開始日時を日本時間に変換
                "startTimeJst" = $item.startTime.AddHours(+9).ToString("yyyy-MM-dd HH:mm:ss")
                # 更新終了日時を日本時間に変換
                "endTimeJst" = $item.endTime.AddHours(+9).ToString("yyyy-MM-dd HH:mm:ss")
                "status" = $item.status
            }
            $editList.Add($data)
        }
        Add_file ($log_file) ("更新履歴の取得終了 -----------------")
    }
    Add_file ($log_file) ("更新履歴結果ファイル出力：" + $output_FilePath)

    # jsonファイル出力
    ConvertTo-Json -InputObject $editList | Out-File -Encoding utf8 -FilePath $output_FilePath

} catch {
    Add_file ($log_file) ("エラーが発生しました：" + $_.Exception)

} finally {
    # Power BIからログアウト
    Disconnect-PowerBIServiceAccont
}

# 終了
Add_file ($log_file) (Get-Date)
Add_file ($log_file) ("End---------------------------------------")