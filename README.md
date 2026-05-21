# BXD EventOps Agent

Agente de coleta de métricas para a plataforma **BXD EventOps**. Gerencia o processo [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) no host do cliente, sincroniza configuração do portal e envia heartbeats e métricas para a API de ingestão.

---

## Instalação

### Pré-requisitos

- Acesso ao portal BXD EventOps (para gerar a chave de registro)
- Windows 10/11 ou Linux (Ubuntu 20.04+, Debian 11+, RHEL 8+) ou macOS 12+
- Conexão à internet para baixar o agente e o Telegraf

### 1. Gere uma chave de registro no portal

No portal BXD EventOps:
1. Acesse **Monitoração → Agentes** do tenant
2. Clique em **Gerar chave de registro**
3. Copie o comando de instalação exibido (válido por 24 horas, uso único)

### 2. Execute o comando no host

**Windows (PowerShell como Administrador):**

```powershell
iwr -Uri "https://raw.githubusercontent.com/bxd-eventops-agents/agent/main/scripts/install.ps1" -OutFile install.ps1
.\install.ps1 --url https://api.eventops.bxd.com.br --key evpr_<sua-chave>
```

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/bxd-eventops-agents/agent/main/scripts/install.sh \
  | sudo bash -s -- --url https://api.eventops.bxd.com.br --key evpr_<sua-chave>
```

O script de bootstrap:
1. Detecta a arquitetura do sistema (amd64 / arm64)
2. Baixa o binário do agente desta página de releases
3. Baixa e extrai o Telegraf
4. Auto-registra o agente no portal usando a chave
5. Registra e inicia o serviço (Windows Service ou systemd)

---

## Verificação

**Windows:**
```powershell
Get-Service "EventOps Agent" | Select-Object Status
```

**Linux:**
```bash
systemctl status eventops-agent
```

---

## Releases

Os binários estão disponíveis na [página de releases](https://github.com/bxd-eventops-agents/agent/releases) para as seguintes plataformas:

| Plataforma | Arquivo |
|---|---|
| Windows x64 | `eventops-agent-windows-amd64.exe` |
| Windows ARM64 | `eventops-agent-windows-arm64.exe` |
| Linux x64 | `eventops-agent-linux-amd64` |
| Linux ARM64 | `eventops-agent-linux-arm64` |
| macOS x64 | `eventops-agent-darwin-amd64` |
| macOS ARM64 (Apple Silicon) | `eventops-agent-darwin-arm64` |

---

## Suporte

- Portal: [eventops.bxd.com.br](https://eventops.bxd.com.br)
- E-mail: suporte@bxd.com.br
