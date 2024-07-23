# tidy-terraform

dev環境については、PR作成で `terraform plan`、main ブランチへのマージで `terraform apply` が実行されます。
prod環境については、ローカルで実行する必要があります。

## ローカルで実行する場合のコマンド

### 開発環境用

**plan**

```
terraform -chdir=envs/dev init
terraform -chdir=envs/dev plan
```

**apply**

```
terraform -chdir=envs/dev init
terraform -chdir=envs/dev apply
```

### 本番環境用

**plan**

```
terraform -chdir=envs/prod init
terraform -chdir=envs/prod plan
```

**apply**

```
terraform -chdir=envs/prod init
terraform -chdir=envs/prod apply
```
