# Диаграммы потоков данных — «Будущее 2.0»

---

## DFD Уровень 1 — Все домены и потоки данных

```mermaid
flowchart TB
    %% ─── Внешние сущности ───────────────────────────────────
    OP(["Оператор клиники"])
    PAT(["Пациент / Клиент"])
    AN(["Аналитик / Менеджер"])
    PHARMA(["Фармкомпания будущий партнёр"])
    DEVMFR(["Производитель медоборудования"])

    %% ─── Медицинский домен ───────────────────────────────────
    subgraph MED["Медицинский домен"]
        direction TB
        P11["1.1 Приём и ведение медкарты"]
        P12["1.2 Аутентификация и аудит доступа"]
        DS1[(DS1: Медицинское хранилище медкарты · снимки · анализы)]
    end

    %% ─── ИИ-домен ────────────────────────────────────────────
    subgraph AID["ИИ-домен"]
        direction TB
        P21["2.1 Анализ медданных диагностика · риски · изображения"]
        DS2[(DS2: Реестр ML-моделей MLflow)]
    end

    %% ─── Финтех-домен ────────────────────────────────────────
    subgraph FIN["Финтех-домен"]
        direction TB
        P31["3.1 Банковские операции кредиты · счета · платежи"]
        P32["3.2 ELT: подготовка финтех-витрины"]
        DS3[(DS3: Финтех БД счета · кредиты · транзакции)]
        DS4[(DS4: Финтех-витрина агрегаты для аналитики)]
    end

    %% ─── Интеграционный слой ─────────────────────────────────
    subgraph INT["Интеграционный слой"]
        KAFKA{{"5.0 Event Streaming Apache Kafka"}}
    end

    %% ─── Корпоративная аналитика ─────────────────────────────
    subgraph CORP["Корпоративная аналитика — Головной офис"]
        direction TB
        P41["4.1 Оркестрация ELT Airflow"]
        P42["4.2 Портал самообслуживания"]
        P43["4.3 BI-платформа Power BI"]
        DS5[(DS5: Corporate Cloud DWH Snowflake / Azure Synapse)]
    end

    %% ─── Партнёрский домен ───────────────────────────────────
    subgraph PART["Партнёрский домен — будущий"]
        P60["6.0 Партнёрский API-шлюз"]
    end

    %% ─── Потоки: Оператор ↔ Медицинский домен ───────────────
    OP -->|"Данные приёма, снимки, жалобы"| P11
    P11 -->|"Диагноз, история болезни, назначения"| OP
    P12 -->|"Контекст доступа (роль, уровень)"| P11
    P11 <-->|"Медкарты и снимки (R/W)"| DS1

    %% ─── Потоки: Медицинский домен ↔ ИИ-домен (синхронно) ───
    P11 -->|"Обезличенные данные + снимок [gRPC]"| P21
    P21 -->|"Результат диагностики (вероятности)"| P11
    P21 <-->|"Загрузка / сохранение ML-моделей"| DS2

    %% ─── Потоки: Медицинский домен → Kafka ──────────────────
    P11 -->|"topic: medical.events Приём завершён — без ПДн"| KAFKA

    %% ─── Потоки: Пациент ↔ Финтех-домен ────────────────────
    PAT -->|"Запрос банковской услуги"| P31
    P31 -->|"Подтверждение, выписка, статус"| PAT
    P31 <-->|"Финансовые данные (R/W)"| DS3
    DS3 -->|"Операционные данные (R)"| P32
    P32 -->|"Агрегированные данные (W)"| DS4

    %% ─── Потоки: Финтех-домен → Kafka ───────────────────────
    P31 -->|"topic: fintech.events Кредит выдан · Платёж проведён"| KAFKA

    %% ─── Потоки: Партнёры → Kafka ───────────────────────────
    PHARMA -->|"Каталог препаратов, обновления цен"| P60
    DEVMFR -->|"Телеметрия устройств, показатели"| P60
    P60 -->|"topic: partners.pharma.v1 topic: partners.devices.v1"| KAFKA

    %% ─── Потоки: Kafka → Корпоративная аналитика ────────────
    KAFKA -->|"Агрегированные события доменов"| P41
    DS4 -->|"Финтех-агрегаты из витрины"| P41
    P41 -->|"Трансформированные данные (ELT)"| DS5
    DS5 -->|"Аналитические данные для запросов"| P42
    DS5 -->|"Данные для дашбордов"| P43
    P43 -->|"Встроенные дашборды"| P42

    %% ─── Потоки: Аналитик ↔ Портал ─────────────────────────
    AN -->|"Выбор срезов, построение отчёта"| P42
    P42 -->|"Отчёт / дашборд (секунды)"| AN

    %% ─── Стили ───────────────────────────────────────────────
    classDef external fill:#DDEEFF,stroke:#2255AA,color:#000,font-weight:bold
    classDef process  fill:#D5F5D5,stroke:#227722,color:#000
    classDef store    fill:#FFFAE0,stroke:#997700,color:#000
    classDef kafka    fill:#FFF3CC,stroke:#AA7700,color:#000,font-weight:bold

    class OP,PAT,AN,PHARMA,DEVMFR external
    class P11,P12,P21,P31,P32,P41,P42,P43,P60 process
    class DS1,DS2,DS3,DS4,DS5 store
    class KAFKA kafka
```

---

## Сценарий А: ИИ-диагностика пациента

```mermaid
sequenceDiagram
    actor OP as Оператор клиники

    box rgb(232,245,233) Медицинский домен
        participant WebUI as Медицинская Web-система
        participant MedAPI as Medical API
        participant MedDB as Медицинское хранилище
    end

    box rgb(227,242,253) ИИ-домен
        participant AI as ИИ-платформа (Python)
        participant MLReg as ML Registry (MLflow)
    end

    participant KAFKA as Kafka [medical.events]

    OP->>WebUI: Открывает приём, загружает снимок
    activate WebUI

    WebUI->>+MedAPI: POST /appointments {patientId, symptoms, scan}

    MedAPI->>MedDB: INSERT medcard (полные данные пациента)
    MedDB-->>MedAPI: medcardId

    MedAPI->>+AI: POST /analyze {anonPatientRef, scan, symptoms} [gRPC — без ПДн]
    AI->>MLReg: GET /models/latest {task: "diagnosis"}
    MLReg-->>AI: model_artifact v3.2
    Note over AI: Инференс модели — анализ снимка и симптомов
    AI-->>-MedAPI: {diagnosis: "pneumonia", confidence: 0.91, recommendations}

    MedAPI->>MedDB: UPDATE medcard — сохранить результат ИИ

    MedAPI->>KAFKA: Produce {type: "appointment_completed", aggMetrics — без ПДн}
    Note over KAFKA: Агрегированные метрики без ПДн:<br/>тип приёма, ИИ-уверенность, длительность

    MedAPI-->>-WebUI: {diagnosis, recommendations}
    WebUI-->>OP: Диагноз ИИ + рекомендации по лечению
    deactivate WebUI
```

---

## Сценарий Б: Запуск нового финтех-продукта (медицинский кредит)

> Новый продукт добавляется **внутри Финтех-домена** — остальные домены не меняются.

```mermaid
sequenceDiagram
    actor PAT as Пациент / Клиент
    participant GW as API Gateway

    box rgb(255,243,224) Финтех-домен
        participant FIN as Финтех-сервисы (Golang)
        participant FinDB as Финтех БД
        participant ELT as ELT-агент
        participant FinDM as Финтех-витрина
    end

    participant KAFKA as Kafka [fintech.events]

    box rgb(237,231,246) Корпоративная аналитика
        participant AIRFLOW as Airflow
        participant DWH as Corporate Cloud DWH
    end

    Note over FIN: Новый микросервис «Медкредит»<br/>добавлен внутри домена.<br/>Остальные домены не менялись.

    PAT->>GW: POST /api/v1/credit/medical-loan {amount, term, purpose}
    GW->>+FIN: Маршрутизация запроса

    FIN->>FinDB: SELECT credit_history WHERE clientId = ?
    FinDB-->>FIN: Кредитная история (0 просрочек)

    FIN->>FinDB: INSERT medical_loan {clientId, amount, rate, term}
    FinDB-->>FIN: loanId = 8843

    FIN->>KAFKA: Produce {type: "loan_issued", product: "medical-loan", amount — без банктайны}
    FIN-->>-GW: {status: "approved", loanId, monthlyPayment}
    GW-->>PAT: Кредит одобрен — ежемесячный платёж 4 500 ₽

    ELT->>FinDB: SELECT агрегированные метрики (по расписанию)
    ELT->>FinDM: UPSERT финтех-агрегаты (по продукту, периоду, подразделению)

    KAFKA-->>AIRFLOW: Consume {type: "loan_issued", ...}
    AIRFLOW->>DWH: INSERT fact_loans {product, amount_bucket, region, timestamp}
    Note over DWH: DWH обновляется без изменений схемы —<br/>новый продукт = новое значение в поле product_type
```

---

## Сценарий В: Подключение новой фармкомпании-партнёра

> Подключение занимает **1–2 спринта**. Существующие домены **не меняются**.

```mermaid
sequenceDiagram
    actor PHARMA as Фармкомпания «АльфаФарм»

    box rgb(250,250,250) Партнёрский домен
        participant PGW as Partner API Gateway
    end

    participant KAFKA as Kafka [partners.pharma.v1]

    box rgb(232,245,233) Медицинский домен
        participant MedAPI as Medical API
        participant DrugDB as Справочник препаратов
    end

    box rgb(237,231,246) Корпоративная аналитика
        participant AIRFLOW as Airflow
        participant DWH as Corporate Cloud DWH
        participant PORTAL as Портал самообслуживания
    end

    actor MANAGER as Менеджер по закупкам

    Note over PGW,KAFKA: Шаг 0 (однократно): Integration Team создаёт<br/>топик «partners.pharma.v1» и Avro-схему.<br/>Существующие домены НЕ меняются.

    PHARMA->>+PGW: POST /catalog/update {drugs: [{sku, name, atcCode, price}]}
    Note over PGW: Валидация по Avro-схеме, нормализация
    PGW->>KAFKA: Produce {partnerId, catalogVersion, drugs: [...]}
    deactivate PGW

    KAFKA-->>MedAPI: Consume (подписка на справочник)
    MedAPI->>DrugDB: UPSERT drug_catalog (sku, name, atcCode, price)
    Note over MedAPI: Врачи видят актуальный каталог<br/>при назначении препаратов

    KAFKA-->>AIRFLOW: Consume (подписка для аналитики)
    AIRFLOW->>DWH: UPSERT dim_drugs (партнёр, sku, цена, дата)

    MANAGER->>PORTAL: Отчёт: закупки по поставщику за квартал
    PORTAL->>DWH: SELECT supplier, drug, SUM(qty), AVG(price) GROUP BY quarter
    DWH-->>PORTAL: Результат выборки
    PORTAL-->>MANAGER: Интерактивный отчёт

    Note over PHARMA,MANAGER: Итог: фармкомпания подключена за 1–2 спринта.<br/>Изменения только в Partner API Gateway<br/>и конфигурации Kafka-консьюмеров.
```

---

## Сценарий Г: Быстрая подготовка управленческого отчёта

> Отчёт готов за **~5 секунд** вместо часов на монолитном DWH.

```mermaid
sequenceDiagram
    actor MANAGER as Менеджер / Аналитик

    box rgb(237,231,246) Корпоративная аналитика
        participant PORTAL as Портал самообслуживания
        participant DWH as Corporate Cloud DWH
        participant BI as BI-платформа (Power BI)
    end

    Note over DWH: Данные предагрегированы:<br/>Airflow загружает ELT near-realtime через Kafka<br/>или по расписанию (5-минутные батчи)

    MANAGER->>+PORTAL: Выбирает срез: все клиники, март 2026<br/>KPI: выручка, кол-во приёмов, доля ИИ-диагнозов<br/>Детализация: по городам

    PORTAL->>+DWH: SELECT city, SUM(revenue), COUNT(appointments),<br/>AVG(ai_diagnosis_rate)<br/>FROM fact_appointments JOIN dim_clinics<br/>WHERE month = '2026-03' GROUP BY city
    Note over DWH: Колоночное хранение + предматериализованные агрегаты<br/>= ответ за 2–5 секунд (вместо часов)
    DWH-->>-PORTAL: ResultSet — 20 строк

    PORTAL->>BI: Embed: запрос дашборда «Динамика по месяцам»
    BI->>DWH: DirectQuery — сравнение с предыдущими периодами
    DWH-->>BI: Исторические данные
    BI-->>PORTAL: Визуальный дашборд

    PORTAL-->>-MANAGER: Интерактивный отчёт + дашборд (~5 секунд)

    MANAGER->>PORTAL: Поделиться ссылкой с коллегами
    PORTAL-->>MANAGER: Ссылка с параметрами среза<br/>(доступна коллегам того же уровня доступа)

    Note over MANAGER: Управленческие решения принимаются<br/>оперативно — без участия IT-команды.
```
