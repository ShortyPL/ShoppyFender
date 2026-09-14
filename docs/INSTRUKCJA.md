# Instrukcja gry — ShopyFender

Zarządzasz sklepem detalicznym w 3D: projektujesz układ, stawiasz półki, przypisujesz produkty, zamawiasz dostawy i otwierasz sklep na falę klientów.

Start: **New Game** w menu (albo **Continue**, jeśli masz zapis). Pełniejszy opis projektu: [README](../README.md).

## Cel

Zarabiaj i utrzymuj zadowolenie klientów. Po każdej fali dostajesz ocenę **1–3 gwiazdek**:

| Cel | Wymaganie (prototyp) |
|---|---|
| Obsłużeni klienci | ≥ 8 (przy fali startowej 10 osób) |
| Satysfakcja | ≥ 80% |
| Utracone sprzedaże | 0 |

Fala rośnie z numerem fali (więcej klientów w kolejnych rundach).

## Pętla rozgrywki

1. **BUILD** — budujesz sklep, ustawiasz towary, zamawiasz stock.
2. **Otwarcie** — **More → Open store** (albo z menu kontekstowego).
3. **Fala** — klienci wchodzą, zbierają produkty, stoją w kolejce do kasy.
4. **RESULTS** — podsumowanie; **Next wave** / **Repeat wave** / powrót do budowy.

Startowy budżet: **10 000**.

## Kamera

| Sterowanie | Działanie |
|---|---|
| **W A S D** | Przesuwanie kamery |
| **Q / E** | Obrót widoku |
| **Scroll** | Zoom |
| **Środkowy przycisk myszy + przeciągnięcie** | Pan |
| Ustawienia → **Sensitivity** | Czułość pana |

## Budowa i półki (tryb BUILD)

| Sterowanie | Działanie |
|---|---|
| **PPM (prawy)** na podłodze / półce | Menu kontekstowe |
| **LPM** | Postawienie ghosta (tryb place) albo wybór półki |
| **R** | Obrót podglądu / ghosta o 90° |
| **Esc** | Anuluj tryb stawiania / zamknij menu |

**Przycisk Build** na dolnym pasku też otwiera wybór mebla.

### Menu na podłodze (PPM)

- **Place fixture…** — wybór typu mebla (koszt z katalogu)
- **Rotate preview 90°**
- **Remove all fixtures**
- **Order stock…** / **Open store**

### Menu na półce (PPM)

- **Place product on shelf…** — przypisz SKU
- **More / Fewer facings** — szerokość ekspozycji
- **Restock to capacity** — uzupełnij z magazynu
- **Clear product**
- **Rotate / Duplicate / Remove shelf**
- **Open store**

Puste półki albo brak towaru w magazynie = utracone sprzedaże i gorsza ocena.

## Pasek akcji (HUD)

| Przycisk | Funkcja |
|---|---|
| **Order** | Zamówienie towaru do magazynu |
| **Build** | Wybór i stawianie mebli |
| **Staff** | Pracownicy, auto-uzupełnianie półek, restock |
| **Upgrades** | Ulepszenia (np. szybsza kasa, druga kasa) |
| **More** | Open store, Menu, Continue (zapis / wyjście) |

Na HUD widać też: gotówkę, dzień/czas, rating, kolejkę, cele fali, podgląd fali i status dostawy.

### Zamówienia (Order)

1. Wybierz produkt.
2. Ilość: **6 / 12 / 24**.
3. Dostawa: **Standard** (po fali) albo **Express** (od razu do magazynu, drożej).
4. Potwierdź **Order** — koszt schodzi z gotówki.

Potem **Restock to capacity** na półce albo staff **Auto-fill / Restock empties**.

## Fala klientów

- Otwórz sklep dopiero gdy półki mają stock.
- Klienci szukają produktów z listy zakupów; brak towaru / zła ścieżka / długa kolejka → lost sales.
- Kasjer obsługuje kolejkę; upgrade’y mogą przyspieszyć kasę lub dodać drugą linię.

## Prędkość gry

| Skrót | Działanie |
|---|---|
| **1 / 2 / 3** | 1× / 2× / 4× |
| **[ ]** lub **+ / −** | Przełączanie prędkości |
| **Spacja** | Pauza / wznowienie |

## Debug (opcjonalnie)

| Skrót | Działanie |
|---|---|
| **F1 / F2** | Overlay debug |
| **F3** | Playtest bot |

## Menu główne

- **New Game** — nowa sesja (czyści zapis)
- **Continue** — wczytaj ostatni zapis
- **Settings** — fullscreen, głośność, czułość kamery
- **Help** — skrócona wersja tej instrukcji
- **Esc** — zamknięcie Help / Settings

---

Szczegóły designu: [Master spec](../ShopyFender_package/SHOPYFENDER_MASTER_SPEC.md) · [Game logic](../ShopyFender_package/SHOPYFENDER_GAME_LOGIC.md)
