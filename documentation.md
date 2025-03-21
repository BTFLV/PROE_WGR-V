# WGR-V Verilog Doku

## Inhaltsverzeichnis

- **Datei:** peripherals/fifo.v
  - [Modul: fifo](#module-fifo)
- **Datei:** peripherals/gpio.v
  - [Modul: gpio](#module-gpio)
- **Datei:** peripherals/seq_multiplier.v
  - [Modul: seq_multiplier](#module-seq_multiplier)


## Datei: peripherals/fifo.v

### <a name="module-fifo"></a>Modul: fifo

**Kurzbeschreibung:** Ein einfacher FIFO-Speicher.

Dieser FIFO (First-In-First-Out) Puffer speichert Daten mit einer konfigurierbaren Breite (`DATA_WIDTH`) und Tiefe (`DEPTH`). Daten werden über das `wr_en` Signal hineingeschrieben und über das `rd_en` Signal ausgelesen. Das Modul liefert die Signale `empty` und `full`, um anzuzeigen, ob weitere Lese- oder Schreibvorgänge möglich sind.

**Parameter:**

- `DATA_WIDTH` Breite der gespeicherten Daten in Bits.
- `DEPTH`      Anzahl der Einträge im FIFO.

**Lokale Parameter:**

- `ADDR_WIDTH` Breite der Adresszeiger basierend auf `DEPTH`.

**Eingänge:**

- `clk`      Systemtakt.
- `rst_n`    Aktiv-low Reset.
- `wr_en`    Aktivierungssignal (Write-Enable) zum Schreiben in den FIFO.
- `rd_en`    Aktivierungssignal (Read-Enable) zum Lesen aus dem FIFO.
- `din`      Eingangsdaten mit Breite `DATA_WIDTH`.

**Ausgänge:**

- `empty`    Signal, das anzeigt, ob der FIFO leer ist.
- `full`     Signal, das anzeigt, ob der FIFO voll ist.
- `dout`     Ausgangsdaten mit Breite `DATA_WIDTH`.

## Datei: peripherals/gpio.v

### <a name="module-gpio"></a>Modul: gpio

**Kurzbeschreibung:** GPIO Modul zur Steuerung allgemeiner I/O.

Dieses Modul implementiert einen einfachen GPIO-Controller. Es unterstützt das Auslesen von Eingangspins und das Schreiben auf Ausgangspins über definierte Adressen. Die Richtungssteuerung (gpio_dir) ist derzeit nicht implementiert.

**Eingänge:**

- `clk`         Systemtakt.
- `rst_n`       Aktiv-low Reset-Signal.
- `address`     Speicheradresse zur Auswahl der GPIO-Register.
- `write_data`  Daten, die in die angesprochenen GPIO-Register geschrieben werden.
- `we`          Schreibaktivierungssignal (Write-Enable).
- `re`          Leseaktivierungssignal (Read-Enable).
- `gpio_in`     Eingangssignale von den GPIO-Pins.

**Ausgänge:**

- `read_data`  Ausgangsdaten basierend auf dem angesprochenen GPIO-Register.
- `gpio_out`   Register zur Steuerung des Ausgangszustands der GPIO-Pins.
- `gpio_dir`   GPIO-Richtungsregister (nicht implementiert).

## Datei: peripherals/seq_multiplier.v

### <a name="module-seq_multiplier"></a>Modul: seq_multiplier

**Kurzbeschreibung:** Sequentieller Multiplikator.

Dieses Modul implementiert eine sequentielle Multiplikation zweier 32-Bit-Werte. Die Multiplikation erfolgt durch aufeinanderfolgende Additionen basierend auf den Bits des Multiplikators.  Das Modul ist speicherabbildbasiert und kann über Adressen gesteuert werden: - `MUL1_OFFSET`: Erster Multiplikand. - `MUL2_OFFSET`: Zweiter Multiplikator (startet die Berechnung). - `RESH_OFFSET`: Höhere 32 Bits des Ergebnisses. - `RESL_OFFSET`: Niedrigere 32 Bits des Ergebnisses. - `INFO_OFFSET`: Gibt an, ob die Berechnung noch läuft (`busy`).

**Lokale Parameter:**

- `INFO_OFFSET` Adresse für den Status (`busy`-Bit).
- `MUL1_OFFSET` Adresse für den ersten Multiplikanden.
- `MUL2_OFFSET` Adresse für den zweiten Multiplikator (startet Berechnung).
- `RESH_OFFSET` Adresse für die höheren 32 Bit des Ergebnisses.
- `RESL_OFFSET` Adresse für die niedrigeren 32 Bit des Ergebnisses.

**Eingänge:**

- `clk`         Systemtakt.
- `rst_n`       Aktiv-low Reset.
- `address`     Speicheradresse für den Zugriff auf Register.
- `write_data`  Daten, die in die ausgewählten Register geschrieben werden sollen.
- `we`          Schreibaktivierungssignal (Write-Enable).
- `re`          Leseaktivierungssignal (Read-Enable).

**Ausgänge:**

- `read_data`   Zu lesende Daten basierend auf der Adresse.

