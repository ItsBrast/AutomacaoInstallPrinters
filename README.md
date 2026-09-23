# 🖨️ Automação de Instalação de Impressoras

Automação desenvolvida em **PowerShell** para padronizar e agilizar o processo de instalação e configuração de impressoras em estações Windows.

O projeto foi desenvolvido com foco em **Infraestrutura de TI, Field Service e automação de tarefas repetitivas**, substituindo etapas manuais por um fluxo automatizado e padronizado.

---

## 📌 Sobre o projeto

A instalação de impressoras em ambientes corporativos pode envolver diversas etapas:

* Localização do equipamento;
* Instalação do driver correto;
* Criação da porta TCP/IP;
* Configuração do protocolo de impressão;
* Criação da fila;
* Configuração das preferências;
* Validação da instalação.

Quando esse processo é realizado manualmente em diversas máquinas, pequenas diferenças de configuração podem gerar problemas e aumentar o tempo necessário para atendimento.

Este projeto busca **padronizar esse processo através de um único script PowerShell**.

---

## 🎯 Objetivos

O principal objetivo é reduzir a quantidade de tarefas manuais necessárias durante o onboarding de uma impressora.

### Principais objetivos

* Automatizar a instalação de drivers;
* Padronizar portas TCP/IP;
* Configurar impressão utilizando RAW;
* Utilizar a porta TCP `9100`;
* Criar ou atualizar filas de impressão;
* Configurar papel padrão A4;
* Validar o resultado da instalação;
* Reduzir erros de configuração manual;
* Facilitar a manutenção e expansão da automação;
* Criar um processo reproduzível para diferentes modelos de impressoras.

---

## ⚙️ Tecnologias utilizadas

| Tecnologia                   | Utilização                                     |
| ---------------------------- | ---------------------------------------------- |
| **PowerShell**               | Linguagem principal da automação               |
| **Windows Print Management** | Gerenciamento de impressoras, drivers e portas |
| **PnPUtil**                  | Adição de pacotes de drivers ao Driver Store   |
| **WMI**                      | Validação das configurações TCP/IP             |
| **TCP/IP**                   | Comunicação com as impressoras                 |
| **RAW / TCP 9100**           | Protocolo utilizado para impressão             |
| **Drivers INF**              | Instalação dos drivers                         |

---

# 🔄 Fluxo de funcionamento

O processo é dividido em várias etapas para garantir que a impressora seja configurada corretamente.

```text
┌──────────────────────────────┐
│            INÍCIO            │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Verificar privilégios Admin  │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│       Carregar CSV           │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Selecionar impressora        │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Verificar conectividade      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Driver já instalado?         │
└───────────┬───────────┬──────┘
            │ SIM       │ NÃO
            │           ▼
            │   ┌──────────────────────┐
            │   │ Instalar via INF     │
            │   │ usando PnPUtil       │
            │   └──────────┬───────────┘
            │              │
            └──────┬───────┘
                   ▼
        ┌────────────────────────┐
        │ Criar/verificar porta  │
        │ TCP/IP                 │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Configurar RAW / 9100  │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Criar ou atualizar     │
        │ fila de impressão      │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Configurar papel A4    │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │ Verificação final      │
        └────────────┬───────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │        CONCLUÍDO       │
        └────────────────────────┘
```

---

# 📂 Estrutura do projeto

```text
Automacao-Impressoras/
│
├── Instalar-impressora.ps1
│
├── impressoras.csv
│
└── Drivers/
    │
    ├── FabricanteA/
    │   └── ...
    │
    ├── FabricanteB/
    │   └── ...
    │
    └── ...
```

## `Instalar-impressora.ps1`

Arquivo principal do projeto.

É responsável por:

* Validar privilégios administrativos;
* Carregar o arquivo de configuração;
* Apresentar as impressoras disponíveis;
* Validar os dados selecionados;
* Verificar conectividade;
* Localizar arquivos `.INF`;
* Instalar drivers;
* Criar portas TCP/IP;
* Configurar RAW + 9100;
* Criar ou atualizar filas;
* Configurar papel A4;
* Realizar validações finais.

---

## `impressoras.csv`

O CSV funciona como uma camada de configuração do projeto.

Isso permite adicionar ou alterar impressoras sem precisar modificar a lógica principal do script.

### Estrutura

```csv
Depto;Fabricante;Modelo;IP;DriverName;DriverFolder
Departamento A;Fabricante A;Modelo A;192.0.2.10;Driver Exemplo;Exemplo
Departamento B;Fabricante B;Modelo B;192.0.2.11;Driver Exemplo 2;Exemplo2
```

### Campos

| Campo          | Descrição                                  |
| -------------- | ------------------------------------------ |
| `Depto`        | Identificação do departamento              |
| `Fabricante`   | Fabricante da impressora                   |
| `Modelo`       | Modelo do equipamento                      |
| `IP`           | Endereço da impressora                     |
| `DriverName`   | Nome do driver registrado no Windows       |
| `DriverFolder` | Diretório onde estão os arquivos do driver |

> Os endereços e nomes apresentados acima são apenas exemplos.

---

# 🖨️ Instalação de drivers

O projeto utiliza arquivos `.INF` para instalação dos drivers.

A função responsável pelo processo realiza algumas validações antes de registrar o driver no Windows.

### Processo

```text
Driver já instalado?
       │
   ┌───┴───┐
   │       │
  SIM     NÃO
   │       │
   │       ▼
   │   Localizar INF
   │       │
   │       ▼
   │    PnPUtil
   │       │
   │       ▼
   │ Driver Store
   │       │
   │       ▼
   │ Verificar registro
   │       │
   └───┬───┘
       ▼
Driver disponível
```

Caso o driver não seja identificado automaticamente, o script procura arquivos `.INF` dentro do diretório configurado.

Também existe uma validação posterior utilizando `Get-PrinterDriver`.

---

# 🌐 Configuração TCP/IP

Após o driver estar disponível, o script verifica a existência da porta TCP/IP.

Caso a porta ainda não exista, ela é criada automaticamente.

A configuração utilizada pelo projeto é:

```text
Protocolo: RAW
Porta: 9100
```

O processo utiliza ferramentas nativas do Windows para configurar a porta.

Além disso, o script realiza uma validação posterior através de WMI para verificar:

* Protocolo;
* Número da porta;
* Status do SNMP.

---

# 🔌 Verificação de conectividade

O script realiza uma tentativa de comunicação com a impressora antes de continuar.

O resultado do ping é tratado como **informação de diagnóstico**.

Isso significa que uma impressora que não responder ao ICMP não é automaticamente considerada indisponível para o restante do processo.

Essa abordagem evita que uma política de rede que bloqueie ICMP impeça desnecessariamente a execução da automação.

---

# 🧩 Criação da fila

Depois da configuração da porta, o script verifica se a fila da impressora já existe.

### Se existir

A fila é atualizada utilizando:

```powershell
Set-Printer
```

### Se não existir

Uma nova fila é criada utilizando:

```powershell
Add-Printer
```

O driver e a porta configurados anteriormente são associados à fila.

---

# 📄 Configuração de impressão

Após a criação ou atualização da fila, o script configura o tamanho padrão do papel como:

```text
A4
```

A configuração é realizada através do cmdlet:

```powershell
Set-PrintConfiguration
```

---

# 🔎 Verificação final

Ao finalizar a instalação, o script realiza uma série de verificações.

São validados:

* Impressora instalada;
* Driver registrado;
* Porta TCP/IP existente;
* Protocolo configurado;
* Porta TCP configurada;
* Configuração de SNMP.

Exemplo conceitual da validação:

```text
[OK] Impressora instalada
[OK] Driver instalado
[OK] Porta TCP/IP configurada

Configuração TCP/IP:
    Protocolo : RAW
    Porta     : 9100
    SNMP      : False
```

---

# 🛡️ Tratamento de erros

O script possui tratamento de erros em diferentes etapas do processo.

Entre os mecanismos utilizados estão:

* `try/catch`;
* `ErrorActionPreference`;
* validação de arquivos;
* validação de drivers;
* validação de portas;
* códigos de saída do `PnPUtil`;
* timeout para registro do driver;
* mensagens de erro específicas;
* interrupção controlada da instalação.

A variável:

```powershell
$ErrorActionPreference = "Stop"
```

faz com que erros não tratados continuem o fluxo silenciosamente, permitindo que o script interrompa etapas críticas quando necessário.

---

# 🔐 Considerações de segurança

O projeto foi estruturado para que informações específicas do ambiente não façam parte da lógica principal do script.

O repositório não deve conter:

* Senhas;
* Tokens;
* API Keys;
* Credenciais;
* Informações de autenticação;
* IPs reais de infraestrutura;
* Dados pessoais;
* Informações internas desnecessárias.

Para demonstração e versionamento, recomenda-se utilizar dados fictícios no arquivo CSV.

---

# 🚀 Como utilizar

### 1. Baixe o projeto

Clone o repositório:

```powershell
git clone <URL_DO_REPOSITORIO>
```

### 2. Configure o CSV

Preencha o `impressoras.csv` de acordo com a estrutura definida.

### 3. Adicione os drivers

Coloque os pacotes de drivers na pasta:

```text
Drivers/
```

Os drivers devem possuir os arquivos necessários para instalação via `.INF`.

### 4. Execute o script

Abra o PowerShell e execute:

```powershell
.\Instalar-impressora.ps1
```

O script solicitará elevação de privilégio através do UAC caso não esteja sendo executado como administrador.

---

# 📋 Requisitos

* Windows 10 ou superior;
* PowerShell;
* Privilégios administrativos;
* Driver compatível;
* Arquivo `.INF` disponível;
* Conectividade de rede com a impressora;
* Impressora configurada para comunicação TCP/IP.
* Arquivo CSV estruturado, exemplo: Depto;Fabricante;Modelo;IP;DriverName;DriverFolder

---

# 💡 Possíveis evoluções

O projeto pode ser expandido futuramente para incluir:

* Detecção automática de modelos;
* Logs estruturados;
* Relatórios de instalação;
* Interface gráfica;
* Validação mais avançada dos drivers;
* Detecção automática de impressoras disponíveis;
* Integração com ferramentas de gerenciamento de endpoints;
* Suporte a novos fabricantes;
* Configuração de scanners;
* Execução remota;
* Modo silencioso para implantação em larga escala.

---

# 📚 Conhecimentos aplicados

Este projeto envolve conceitos de:

**PowerShell**

* Funções;
* Parâmetros;
* Tratamento de exceções;
* Manipulação de arquivos;
* CSV;
* Variáveis de ambiente;
* Processos;
* Elevação de privilégios.

**Windows**

* Print Management;
* Driver Store;
* PnPUtil;
* WMI;
* TCP/IP;
* Filas de impressão;
* Portas de impressão.

**Infraestrutura**

* Padronização;
* Automação;
* Troubleshooting;
* Configuração de endpoints;
* Gerenciamento de periféricos;
* Redução de tarefas repetitivas.

---

# 👨‍💻 Sobre

Projeto desenvolvido como prática de **automação de infraestrutura e suporte técnico**, aplicando PowerShell para transformar um processo operacional repetitivo em um fluxo padronizado e reproduzível.

O projeto também demonstra a aplicação prática de conhecimentos relacionados a **Windows, redes, drivers, impressão e automação de tarefas de Field Service**.

---

## 📄 Licença

Este projeto é disponibilizado para fins de **estudo, demonstração e portfólio**.

Consulte os termos de licenciamento dos respectivos fabricantes antes de redistribuir qualquer pacote de driver.
