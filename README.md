# MMC Project - Translator Jawa ↔ Indonesia

Website hasil dapat diakses di: **[mmcproject.web.id](https://mmcproject.web.id)**
Unduh APK di: **[Kamus Bahasa Jawa](https://github.com/heruarbianto/translateIdtoJV/blob/master/kamusIdtoJv.apk)**

## API Uji Coba Backend

Endpoint API:
**[kamus.mmcproject.web.id/api/idtojv](https://kamus.mmcproject.web.id/api/idtojv)**

### Format Permintaan (Request Body)

#### 1. Terjemahan Indonesia ke Ngoko

```json
{
  "text": "aku dan kamu",
  "from": "id",
  "to": "ng"
}
```

#### 2. Terjemahan Indonesia ke Krama Lugu

```json
{
  "text": "aku dan kamu",
  "from": "id",
  "to": "kl"
}
```

#### 3. Terjemahan Indonesia ke Krama Alus

```json
{
  "text": "aku dan kamu",
  "from": "id",
  "to": "ka"
}
```

#### 4. Terjemahan Jawa ke Indonesia

```json
{
  "text": "aku dan kamu",
  "from": "jw",
  "to": "id"
}
```
