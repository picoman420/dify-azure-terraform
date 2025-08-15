resource "azurerm_log_analytics_workspace" "aca" {
  name                = "logaw-dify-${var.region}-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "dify" {
  name                       = "cae-dify-${var.region}-001"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.aca.id
  infrastructure_subnet_id   = azurerm_subnet.aca.id

  infrastructure_resource_group_name = "rg-dify_managed-env"
  tags                               = {}

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
    maximum_count         = 0
    minimum_count         = 0
  }

  # 各コンテナがデータ系のサービスを必要とするので、依存関係を ACA env に設定しておく
  depends_on = [
    azurerm_redis_cache.redis,
    azurerm_postgresql_flexible_server.postgres
  ]
}

# 各コンテナに必要な環境変数をファイルからローカル変数に読み込む
locals {
  env_nginx = tomap({
    for line in split("\n", file("./env-vars/.env.nginx")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_plugindaemon = tomap({
    for line in split("\n", file("./env-vars/.env.plugindaemon")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_sandbox = tomap({
    for line in split("\n", file("./env-vars/.env.sandbox")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_ssrfproxy = tomap({
    for line in split("\n", file("./env-vars/.env.ssrfproxy")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_api = tomap({
    for line in split("\n", file("./env-vars/.env.api")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_web = tomap({
    for line in split("\n", file("./env-vars/.env.web")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  env_worker = tomap({
    for line in split("\n", file("./env-vars/.env.worker")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })

  # api, worker, plugin_daemon に共通の環境変数はここに定義
  env_shared = tomap({
    for line in split("\n", file("./env-vars/.env.shared")) :
    split("=", line)[0] => join("=", slice(split("=", line), 1, length(split("=", line))))
    if length(split("=", line)) >= 2 && !startswith(line, "#")
  })
}

resource "azurerm_container_app_environment_storage" "nginx_conf" {
  name                         = "caest-nginx-conf"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
  share_name                   = module.fileshare_nginx_conf.share_name
}

resource "azurerm_container_app_environment_storage" "nginx_entrypoint" {
  name                         = "caest-nginx-entrypoint"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
  share_name                   = module.fileshare_nginx_entrypoint.share_name
}

resource "azurerm_container_app_environment_storage" "ssrfproxy_conf" {
  name                         = "caest-ssrfproxy-conf"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_ssrfproxy_conf.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "ssrfproxy_entrypoint" {
  name                         = "caest-ssrfproxy-entrypoint"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_ssrfproxy_entrypoint.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "sandbox_dependencies" {
  name                         = "caest-sandbox-dependencies"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_sandbox_dependencies.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "sandbox_conf" {
  name                         = "caest-sandbox-conf"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_sandbox_conf.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "api_storage" {
  name                         = "caest-api-storage"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_api_storage.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app_environment_storage" "plugindaemon_storage" {
  name                         = "caest-plugindaemon-storage"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  account_name                 = azurerm_storage_account.aca_storage.name
  share_name                   = module.fileshare_plugindaemon_storage.share_name
  access_key                   = azurerm_storage_account.aca_storage.primary_access_key
  access_mode                  = "ReadWrite"
}

resource "azurerm_container_app" "nginx" {
  name                         = "nginx"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    http_scale_rule {
      name                = "nginx"
      concurrent_requests = "10"
    }

    max_replicas = 10
    min_replicas = 1

    container {
      name   = "nginx"
      image  = "nginx:latest"
      cpu    = 0.5
      memory = "1Gi"


      command = [
        "sh",
        "-c",
        "cp -r /mnt/nginx/conf/* /etc/nginx && chmod +x /mnt/entrypoint/docker-entrypoint.sh && /mnt/entrypoint/docker-entrypoint.sh"
      ]

      # 直接 /etc/nginx にマウントすると、nginx の設定が上書きされてしまうので、別の場所にマウントしてから cp する
      volume_mounts {
        name = "nginx-conf"
        path = "/mnt/nginx/conf"
      }

      volume_mounts {
        name = "nginx-entrypoint"
        path = "/mnt/entrypoint"
      }

      dynamic "env" {
        for_each = local.env_nginx
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    volume {
      name         = "nginx-conf"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.nginx_conf.name
    }

    volume {
      name         = "nginx-entrypoint"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.nginx_entrypoint.name
    }
  }

  ingress {
    target_port      = 80
    external_enabled = true

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

resource "azurerm_container_app" "ssrfproxy" {
  name                         = "ssrfproxy"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    tcp_scale_rule {
      name                = "ssrfproxy"
      concurrent_requests = "10"
    }

    max_replicas = 10
    min_replicas = 1

    container {
      name   = "ssrfproxy"
      image  = "ubuntu/squid:latest"
      cpu    = 0.5
      memory = "1Gi"

      command = [
        "sh",
        "-c",
        "cp -r /mnt/squid/* /etc/squid && chmod +x /mnt/entrypoint/docker-entrypoint.sh && /mnt/entrypoint/docker-entrypoint.sh"
      ]

      # 直接 /etc/squid にマウントすると設定が上書きされてしまうので、別の場所にマウントしてから cp する
      volume_mounts {
        name = "ssrfproxy-conf"
        path = "/mnt/squid"
      }

      volume_mounts {
        name = "ssrfproxy-entrypoint"
        path = "/mnt/entrypoint"
      }

      dynamic "env" {
        for_each = local.env_ssrfproxy
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    volume {
      name         = "ssrfproxy-conf"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.ssrfproxy_conf.name
    }

    volume {
      name         = "ssrfproxy-entrypoint"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.ssrfproxy_entrypoint.name
    }
  }

  ingress {
    target_port = 3128
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "sandbox" {
  name                         = "sandbox"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    tcp_scale_rule {
      name                = "sandbox"
      concurrent_requests = "10"
    }

    max_replicas = 10
    min_replicas = 1

    container {
      name   = "langgenius"
      image  = var.dify-sandbox-image
      cpu    = 0.5
      memory = "1Gi"

      volume_mounts {
        name = "sandbox-dependencies"
        path = "/dependencies"
      }

      volume_mounts {
        name = "sandbox-conf"
        path = "/conf"
      }

      dynamic "env" {
        for_each = local.env_sandbox
        content {
          name  = env.key
          value = env.value
        }
      }
    }

    volume {
      name         = "sandbox-dependencies"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.sandbox_dependencies.name
    }

    volume {
      name         = "sandbox-conf"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.sandbox_conf.name
    }
  }

  ingress {
    target_port = 8194
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "plugindaemon" {
  name                         = "plugindaemon"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    tcp_scale_rule {
      name                = "plugindaemon"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 1

    container {
      name   = "langgenius"
      image  = var.dify-plugindaemon-image
      cpu    = 0.5
      memory = "1Gi"

      volume_mounts {
        name = "plugindaemon-storage"
        path = "/app/storage"
      }

      dynamic "env" {
        for_each = local.env_shared
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.env_plugindaemon
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "DB_USERNAME"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.dify_plugin.name
      }
      env {
        name  = "PGUSER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "POSTGRES_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "POSTGRES_DB"
        value = azurerm_postgresql_flexible_server_database.dify_plugin.name
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }
      env {
        name  = "CELERY_BROKER_URL"
        value = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6379/1"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = azurerm_storage_account.aca_storage.name
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_KEY"
        value = azurerm_storage_account.aca_storage.primary_access_key
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_URL"
        value = azurerm_storage_account.aca_storage.primary_blob_endpoint
      }
      env {
        name  = "AZURE_BLOB_CONTAINER_NAME"
        value = azurerm_storage_container.dify_data.name
      }
    }

    volume {
      name         = "plugindaemon-storage"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.plugindaemon_storage.name
    }
  }

  ingress {
    target_port  = 5002
    exposed_port = 5002
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "api" {
  name                         = "api"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  depends_on = [azurerm_container_app.nginx]

  template {
    tcp_scale_rule {
      name                = "api"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 1

    container {
      name   = "langgenius"
      image  = var.dify-api-image
      cpu    = 2
      memory = "4Gi"

      volume_mounts {
        name = "api-storage"
        path = "/app/api/storage"
      }

      dynamic "env" {
        for_each = local.env_shared
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.env_api
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "CONSOLE_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "CONSOLE_WEB_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "SERVICE_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "APP_WEB_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "FILES_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "DB_USERNAME"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.dify.name
      }
      env {
        name  = "PGUSER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "POSTGRES_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "POSTGRES_DB"
        value = azurerm_postgresql_flexible_server_database.dify.name
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }
      env {
        name  = "CELERY_BROKER_URL"
        value = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6379/1"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = azurerm_storage_account.aca_storage.name
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_KEY"
        value = azurerm_storage_account.aca_storage.primary_access_key
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_URL"
        value = azurerm_storage_account.aca_storage.primary_blob_endpoint
      }
      env {
        name  = "AZURE_BLOB_CONTAINER_NAME"
        value = azurerm_storage_container.dify_data.name
      }
      env {
        name  = "PGVECTOR_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "PGVECTOR_USER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "PGVECTOR_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "PGVECTOR_DATABASE"
        value = azurerm_postgresql_flexible_server_database.pgvector.name
      }
    }

    volume {
      name         = "api-storage"
      storage_type = "AzureFile"
      storage_name = azurerm_container_app_environment_storage.api_storage.name
    }
  }

  ingress {
    target_port  = 5001
    exposed_port = 5001
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "web" {
  name                         = "web"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  depends_on = [azurerm_container_app.nginx]

  template {
    tcp_scale_rule {
      name                = "web"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 1

    container {
      name   = "langgenius"
      image  = var.dify-web-image
      cpu    = 1
      memory = "2Gi"

      dynamic "env" {
        for_each = local.env_web
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "CONSOLE_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "APP_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
    }
  }

  ingress {
    target_port  = 3000
    exposed_port = 3000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
    transport = "tcp"
  }
}

resource "azurerm_container_app" "worker" {
  name                         = "worker"
  container_app_environment_id = azurerm_container_app_environment.dify.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  depends_on = [azurerm_container_app.nginx]

  template {
    tcp_scale_rule {
      name                = "worker"
      concurrent_requests = "10"
    }
    max_replicas = 10
    min_replicas = 1

    container {
      name   = "langgenius"
      image  = var.dify-api-image
      cpu    = 2
      memory = "4Gi"

      dynamic "env" {
        for_each = local.env_shared
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.env_worker
        content {
          name  = env.key
          value = env.value
        }
      }

      env {
        name  = "CONSOLE_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "CONSOLE_WEB_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "SERVICE_API_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "APP_WEB_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "FILES_URL"
        value = "https://${azurerm_container_app.nginx.latest_revision_fqdn}"
      }
      env {
        name  = "DB_USERNAME"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "DB_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_DATABASE"
        value = azurerm_postgresql_flexible_server_database.dify.name
      }
      env {
        name  = "PGUSER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "POSTGRES_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "POSTGRES_DB"
        value = azurerm_postgresql_flexible_server_database.dify.name
      }
      env {
        name  = "REDIS_HOST"
        value = azurerm_redis_cache.redis.hostname
      }
      env {
        name  = "REDIS_PASSWORD"
        value = azurerm_redis_cache.redis.primary_access_key
      }
      env {
        name  = "CELERY_BROKER_URL"
        value = "redis://:${azurerm_redis_cache.redis.primary_access_key}@${azurerm_redis_cache.redis.hostname}:6379/1"
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_NAME"
        value = azurerm_storage_account.aca_storage.name
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_KEY"
        value = azurerm_storage_account.aca_storage.primary_access_key
      }
      env {
        name  = "AZURE_BLOB_ACCOUNT_URL"
        value = azurerm_storage_account.aca_storage.primary_blob_endpoint
      }
      env {
        name  = "AZURE_BLOB_CONTAINER_NAME"
        value = azurerm_storage_container.dify_data.name
      }
      env {
        name  = "PGVECTOR_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "PGVECTOR_USER"
        value = azurerm_postgresql_flexible_server.postgres.administrator_login
      }
      env {
        name  = "PGVECTOR_PASSWORD"
        value = azurerm_postgresql_flexible_server.postgres.administrator_password
      }
      env {
        name  = "PGVECTOR_DATABASE"
        value = azurerm_postgresql_flexible_server_database.pgvector.name
      }
    }
  }
}

output "dify-app-url" {
  value = azurerm_container_app.nginx.latest_revision_fqdn
}
