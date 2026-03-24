# 醫療品質指標後端 API

## 快速啟動

```bash
# 1. 安裝套件
npm install

# 2. 啟動伺服器
npm start

# 3. 測試
開啟瀏覽器：http://localhost:3000/health
```

## API 使用方法

### 健康檢查
```
GET http://localhost:3000/health
```

### 計算指標
```
POST http://localhost:3000/api/calculate

Body:
{
  "indicatorId": "indicator-01",
  "fhirServer": "https://hapi.fhir.org/baseR4",
  "quarter": "2025-Q4"
}

回應:
{
  "numerator": 12,
  "denominator": 158,
  "rate": "7.59",
  "quarter": "2025-Q4"
}
```

## 已實作的指標

- ✅ indicator-01: 門診注射劑使用率
- ✅ indicator-02: 門診抗生素使用率
- ⏳ indicator-03~39: 尚未實作（回傳預設值）

## 新增指標計算

複製 `calculateIndicator01` 函數，改名為 `calculateIndicatorXX`，修改計算邏輯即可。
