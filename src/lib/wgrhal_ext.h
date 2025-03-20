/**
 * @file wgrhal_ext.h
 * @brief Erweiterte Funktionen und Hardwarezugriffe für den WGR-V-Prozessor.
 *
 * Diese Header-Datei erweitert die Basisfunktionen um Hardwareunterstützung für
 * Multiplikation, Division, SPI-Kommunikation, WS2812B LED-Steuerung, PWM-basierte
 * Tonerzeugung, dynamischen Speicher (malloc) sowie ein SSD1351 Display mit Terminal-Funktionen.
 */

#ifndef WGRHAL_EXT_H
#define WGRHAL_EXT_H

#include "wgrtypes.h"

#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

/** @def MULT_BASE_ADDR
 *  @brief Basisadresse für den Hardware-Multiplikator.
 */
#define MULT_BASE_ADDR 0x00000500
/** @def MULT_INFO_OFFSET
 *  @brief Offset für das Informationsregister des Multiplikators.
 */
#define MULT_INFO_OFFSET 0x0000
/** @def MUL1_OFFSET
 *  @brief Offset für den ersten Multiplikanden.
 */
#define MUL1_OFFSET 0x0004
/** @def MUL2_OFFSET
 *  @brief Offset für den zweiten Multiplikanden.
 */
#define MUL2_OFFSET 0x0008
/** @def RESH_OFFSET
 *  @brief Offset für die höheren 32-Bit des 64-Bit-Ergebnisses.
 */
#define RESH_OFFSET 0x000C
/** @def RESL_OFFSET
 *  @brief Offset für die niederwertigen 32-Bit des 64-Bit-Ergebnisses.
 */
#define RESL_OFFSET 0x0010

/** @def DIV_BASE_ADDR
 *  @brief Basisadresse für den Hardware-Divider.
 */
#define DIV_BASE_ADDR 0x00000600
/** @def DIV_INFO_OFFSET
 *  @brief Offset für das Informationsregister des Dividers.
 */
#define DIV_INFO_OFFSET 0x00
/** @def DIV_END_OFFSET
 *  @brief Offset für den Dividend.
 */
#define DIV_END_OFFSET 0x04
/** @def DIV_SOR_OFFSET
 *  @brief Offset für den Divisor.
 */
#define DIV_SOR_OFFSET 0x08
/** @def DIV_QUO_OFFSET
 *  @brief Offset für den Quotienten.
 */
#define DIV_QUO_OFFSET 0x0C
/** @def DIV_REM_OFFSET
 *  @brief Offset für den Rest.
 */
#define DIV_REM_OFFSET 0x10

/** @def SPI_BASE_ADDR
 *  @brief Basisadresse für die SPI-Schnittstelle.
 */
#define SPI_BASE_ADDR 0x00000700
/** @def SPI_CTRL_OFFSET
 *  @brief Offset für das SPI-Steuerregister.
 */
#define SPI_CTRL_OFFSET 0x0000
/** @def SPI_CLK_OFFSET
 *  @brief Offset für das SPI-Taktregister.
 */
#define SPI_CLK_OFFSET 0x0004
/** @def SPI_STATUS_OFFSET
 *  @brief Offset für das SPI-Statusregister.
 */
#define SPI_STATUS_OFFSET 0x0008
/** @def SPI_TX_OFFSET
 *  @brief Offset für das SPI-Sende-Register.
 */
#define SPI_TX_OFFSET 0x000C
/** @def SPI_RX_OFFSET
 *  @brief Offset für das SPI-Empfangsregister.
 */
#define SPI_RX_OFFSET 0x0010
/** @def SPI_CS_OFFSET
 *  @brief Offset für die SPI-Chipselect-Steuerung.
 */
#define SPI_CS_OFFSET 0x0014

/** @def WS_BASE_ADDR
 *  @brief Basisadresse für die WS2812B LED-Steuerung.
 */
#define WS_BASE_ADDR 0x00000900

/** @brief Struktur zur Darstellung einer RGB-Farbe.
 */
typedef struct
{
    uint8_t r; /**< Rotanteil */
    uint8_t g; /**< Grünanteil */
    uint8_t b; /**< Blauanteil */
} rgb_color_t;

/** @brief Struktur zur Rückgabe eines Divisionsergebnisses.
 */
typedef struct
{
    uint32_t dividend;  /**< Dividend */
    uint32_t divisor;   /**< Divisor */
    uint32_t quotient;  /**< Quotient */
    uint32_t remainder; /**< Rest */
} div_result_t;

/* Hardware Multiplication and Division */
/**
 * @brief Berechnet das 64-Bit-Ergebnis einer Multiplikation.
 *
 * @param multiplicand Erster Faktor.
 * @param multiplier Zweiter Faktor.
 * @return 64-Bit-Ergebnis der Multiplikation.
 */
uint64_t mult_calc_64(uint32_t multiplicand, uint32_t multiplier);

/**
 * @brief Berechnet das 32-Bit-Ergebnis einer Multiplikation.
 *
 * @param multiplicand Erster Faktor.
 * @param multiplier Zweiter Faktor.
 * @return Niederwertiger 32-Bit-Teil des Multiplikationsergebnisses.
 */
uint32_t mult_calc(uint32_t multiplicand, uint32_t multiplier);

/**
 * @brief Führt eine Division durch und liefert Quotient und Rest.
 *
 * @param dividend Dividend.
 * @param divisor Divisor.
 * @param result Zeiger auf eine div_result_t-Struktur, in der Quotient und Rest gespeichert werden.
 * @return 0 bei Erfolg, -1 bei Fehler (z.B. Division durch 0 oder ungültiger Pointer).
 */
int32_t div_calc(uint32_t dividend, uint32_t divisor, div_result_t *result);

/**
 * @brief Berechnet den Quotienten einer Division.
 *
 * @param dividend Dividend.
 * @param divisor Divisor.
 * @return Quotient oder -1 bei Division durch 0.
 */
uint32_t div_calc_quotient(uint32_t dividend, uint32_t divisor);

/**
 * @brief Berechnet den Rest einer Division.
 *
 * @param dividend Dividend.
 * @param divisor Divisor.
 * @return Rest oder -1 bei Division durch 0.
 */
uint32_t div_calc_remainder(uint32_t dividend, uint32_t divisor);

/* SPI Functions */
/**
 * @brief Aktiviert die SPI-Schnittstelle.
 */
void spi_enable(void);

/**
 * @brief Deaktiviert die SPI-Schnittstelle.
 */
void spi_disable(void);

/**
 * @brief Aktiviert oder deaktiviert den automatischen Chipselect (CS) der SPI-Schnittstelle.
 *
 * @param active true zum Aktivieren, false zum Deaktivieren.
 */
void spi_automatic_cs(bool active);

/**
 * @brief Setzt den SPI-Chipselect-Zustand.
 *
 * @param active Aktiver Zustand (z. B. 0 oder 1).
 */
void spi_cs(uint32_t active);

/**
 * @brief Setzt den Takt-Offset der SPI-Schnittstelle.
 *
 * @param offset Neuer Offsetwert.
 */
void spi_set_clock_offet(uint32_t offset);

/**
 * @brief Konfiguriert den Taktteiler der SPI-Schnittstelle.
 *
 * @param divider Wert des Taktteilers.
 */
void spi_set_clock_divider(uint32_t divider);

/**
 * @brief Liest den aktuellen Status der SPI-Schnittstelle.
 *
 * @return Statuswert.
 */
uint32_t spi_get_status(void);

/**
 * @brief Prüft, ob das SPI-FIFO voll ist.
 *
 * @return 1 wenn voll, sonst 0.
 */
uint32_t spi_fifo_full(void);

/**
 * @brief Prüft, ob die SPI-Schnittstelle bereit ist.
 *
 * @return 1 wenn bereit, sonst 0.
 */
uint32_t spi_is_ready(void);

/**
 * @brief Prüft, ob die SPI-Schnittstelle beschäftigt ist.
 *
 * @return 1 wenn beschäftigt, sonst 0.
 */
uint32_t spi_is_busy(void);

/**
 * @brief Prüft, ob der SPI-Empfangspuffer voll ist.
 *
 * @return 1 wenn voll, sonst 0.
 */
uint32_t spi_rx_full(void);

/**
 * @brief Prüft, ob der SPI-Empfangspuffer leer ist.
 *
 * @return 1 wenn leer, sonst 0.
 */
uint32_t spi_rx_empty(void);

/**
 * @brief Prüft, ob der SPI-Sende-Puffer voll ist.
 *
 * @return 1 wenn voll, sonst 0.
 */
uint32_t spi_tx_full(void);

/**
 * @brief Prüft, ob der SPI-Sende-Puffer leer ist.
 *
 * @return 1 wenn leer, sonst 0.
 */
uint32_t spi_tx_empty(void);

/**
 * @brief Wartet darauf, dass Daten im SPI-Empfangspuffer verfügbar sind.
 *
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Timeout.
 */
int32_t spi_wait_rx_data(uint32_t timeout_ms);

/**
 * @brief Sendet ein Byte über die SPI-Schnittstelle.
 *
 * @param data Zu sendendes Byte.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Timeout.
 */
int32_t spi_write_byte(uint8_t data, uint32_t timeout_ms);

/**
 * @brief Liest ein Byte von der SPI-Schnittstelle.
 *
 * @param data Zeiger, in den das gelesene Byte gespeichert wird.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Timeout.
 */
int32_t spi_read_byte(uint8_t *data, uint32_t timeout_ms);

/**
 * @brief Sendet einen Datenpuffer über SPI.
 *
 * @param buf Zeiger auf den zu sendenden Puffer.
 * @param length Länge des Puffers.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t spi_write_buffer(const uint8_t *buf, uint32_t length, uint32_t timeout_ms);

/**
 * @brief Sendet einen 32-Bit-Wert über SPI.
 *
 * @param value Zu sendender Wert.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t spi_write_uint32(uint32_t value, uint32_t timeout_ms);

/**
 * @brief Liest einen Datenpuffer von der SPI-Schnittstelle.
 *
 * @param buf Zeiger auf den Zielpuffer.
 * @param length Länge des Puffers.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t spi_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms);

/* WS2812B Functions */
/**
 * @brief Setzt die Farbe einer WS2812B LED.
 *
 * @param led LED-Index (0-7).
 * @param color Neue Farbe als rgb_color_t.
 * @return 0 bei Erfolg, -1 bei ungültigem LED-Index.
 */
int32_t ws2812_set_color(uint8_t led, rgb_color_t color);

/**
 * @brief Liest die aktuell gesetzte Farbe einer WS2812B LED.
 *
 * @param led LED-Index (0-7).
 * @return Aktuelle Farbe als rgb_color_t.
 */
rgb_color_t ws2812_get_color(uint8_t led);

/**
 * @brief Schreibt die Farben aller 8 WS2812B LEDs.
 *
 * @param colors Array von 8 rgb_color_t-Werten.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t ws2812_write_all(const rgb_color_t colors[8]);

/**
 * @brief Füllt alle WS2812B LEDs mit einer einheitlichen Farbe.
 *
 * @param color Farbe, mit der alle LEDs gefüllt werden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t ws2812_fill(rgb_color_t color);

/**
 * @brief Schaltet alle WS2812B LEDs aus.
 */
void ws2812_clear(void);

#ifdef PWM_NOTES
/* Play Frequencies with the PWM Module */
/**
 * @brief Aufzählung der Noten im Halbtonsystem.
 */
typedef enum
{
    NOTE_C = 0,   /**< Note C */
    NOTE_Cs = 1,  /**< Cis */
    NOTE_D = 2,   /**< Note D */
    NOTE_Ds = 3,  /**< Dis */
    NOTE_E = 4,   /**< Note E */
    NOTE_F = 5,   /**< Note F */
    NOTE_Fs = 6,  /**< Fis */
    NOTE_G = 7,   /**< Note G */
    NOTE_Gs = 8,  /**< Gis */
    NOTE_A = 9,   /**< Note A */
    NOTE_As = 10, /**< Ais */
    NOTE_B = 11   /**< Note B */
} note_t;

/**
 * @brief Frequenztabelle für Noten (Halbton-Basis).
 */
extern const uint8_t note_freq_halfbase[12];

/**
 * @brief Berechnet Notenparameter für den PWM-Modus.
 *
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int pwm_precompute_notes(void);

/**
 * @brief Spielt eine bestimmte Note in einer festgelegten Oktave über den PWM aus.
 *
 * @param note Gewünschte Note (note_t).
 * @param octave Oktave (z.B. 4).
 */
void pwm_play_note(note_t note, uint32_t octave);

/**
 * @brief Gibt den für PWM-Noten reservierten Speicher frei.
 */
void pwm_free_note_buffer(void);

#endif

#ifdef MALLOC
/* malloc */
/**
 * @brief Start- und Endadressen des Heaps und Stacks (extern deklariert).
 */
extern char _heap_start;
extern char _heap_end;
extern char _sstack;
extern char _estack;

/**
 * @brief Allokiert einen Speicherblock.
 *
 * @param size Größe des benötigten Speichers in Byte.
 * @return Zeiger auf den allokierten Speicher oder NULL bei Fehler.
 */
void *malloc(uint32_t size);

/**
 * @brief Gibt einen zuvor allokierten Speicherblock frei.
 *
 * @param ptr Zeiger auf den Speicherblock.
 */
void free(void *ptr);

/**
 * @brief Ändert die Größe eines allokierten Speicherblocks.
 *
 * @param ptr Zeiger auf den Speicherblock.
 * @param size Neue Größe in Byte.
 * @return Zeiger auf den neuen Speicherblock oder NULL bei Fehler.
 */
void *realloc(void *ptr, uint32_t size);

/**
 * @brief Allokiert einen Speicherblock für ein Array und initialisiert diesen mit 0.
 *
 * @param nmemb Anzahl der Elemente.
 * @param size Größe eines Elements in Byte.
 * @return Zeiger auf den allokierten Speicher oder NULL bei Fehler.
 */
void *calloc(uint32_t nmemb, uint32_t size);

/**
 * @brief Ermittelt den aktuell freien Heap-Speicher.
 *
 * @return Freier Speicher in Byte.
 */
uint32_t heap_free_space(void);

#endif

#ifdef SSD1351
/* SSD1351 Display with Scroll Function */
/**
 * @brief 5x7 Fontdefinition für die Anzeige (ASCII 32-127).
 */
static const uint8_t font5x7[96][5] = {
    {0x00, 0x00, 0x00, 0x00, 0x00}, // ' ' (32)
    {0x00, 0x00, 0x5F, 0x00, 0x00}, // '!' (33)
    {0x00, 0x07, 0x00, 0x07, 0x00}, // '"' (34)
    {0x14, 0x7F, 0x14, 0x7F, 0x14}, // '#' (35)
    {0x24, 0x2A, 0x7F, 0x2A, 0x12}, // '$' (36)
    {0x23, 0x13, 0x08, 0x64, 0x62}, // '%' (37)
    {0x36, 0x49, 0x55, 0x22, 0x50}, // '&' (38)
    {0x00, 0x05, 0x03, 0x00, 0x00}, // ''' (39)
    {0x00, 0x1C, 0x22, 0x41, 0x00}, // '(' (40)
    {0x00, 0x41, 0x22, 0x1C, 0x00}, // ')' (41)
    {0x14, 0x08, 0x3E, 0x08, 0x14}, // '*' (42)
    {0x08, 0x08, 0x3E, 0x08, 0x08}, // '+' (43)
    {0x00, 0x50, 0x30, 0x00, 0x00}, // ',' (44)
    {0x08, 0x08, 0x08, 0x08, 0x08}, // '-' (45)
    {0x00, 0x60, 0x60, 0x00, 0x00}, // '.' (46)
    {0x20, 0x10, 0x08, 0x04, 0x02}, // '/' (47)
    {0x3E, 0x51, 0x49, 0x45, 0x3E}, // '0' (48)
    {0x00, 0x42, 0x7F, 0x40, 0x00}, // '1' (49)
    {0x42, 0x61, 0x51, 0x49, 0x46}, // '2' (50)
    {0x21, 0x41, 0x45, 0x4B, 0x31}, // '3' (51)
    {0x18, 0x14, 0x12, 0x7F, 0x10}, // '4' (52)
    {0x27, 0x45, 0x45, 0x45, 0x39}, // '5' (53)
    {0x3C, 0x4A, 0x49, 0x49, 0x30}, // '6' (54)
    {0x01, 0x71, 0x09, 0x05, 0x03}, // '7' (55)
    {0x36, 0x49, 0x49, 0x49, 0x36}, // '8' (56)
    {0x06, 0x49, 0x49, 0x29, 0x1E}, // '9' (57)
    {0x00, 0x36, 0x36, 0x00, 0x00}, // ':' (58)
    {0x00, 0x56, 0x36, 0x00, 0x00}, // ';' (59)
    {0x08, 0x14, 0x22, 0x41, 0x00}, // '<' (60)
    {0x14, 0x14, 0x14, 0x14, 0x14}, // '=' (61)
    {0x00, 0x41, 0x22, 0x14, 0x08}, // '>' (62)
    {0x02, 0x01, 0x51, 0x09, 0x06}, // '?' (63)
    {0x32, 0x49, 0x79, 0x41, 0x3E}, // '@' (64)
    {0x7E, 0x11, 0x11, 0x11, 0x7E}, // 'A' (65)
    {0x7F, 0x49, 0x49, 0x49, 0x36}, // 'B' (66)
    {0x3E, 0x41, 0x41, 0x41, 0x22}, // 'C' (67)
    {0x7F, 0x41, 0x41, 0x22, 0x1C}, // 'D' (68)
    {0x7F, 0x49, 0x49, 0x49, 0x41}, // 'E' (69)
    {0x7F, 0x09, 0x09, 0x09, 0x01}, // 'F' (70)
    {0x3E, 0x41, 0x49, 0x49, 0x7A}, // 'G' (71)
    {0x7F, 0x08, 0x08, 0x08, 0x7F}, // 'H' (72)
    {0x00, 0x41, 0x7F, 0x41, 0x00}, // 'I' (73)
    {0x20, 0x40, 0x41, 0x3F, 0x01}, // 'J' (74)
    {0x7F, 0x10, 0x28, 0x44, 0x00}, // 'K' (75)
    {0x7F, 0x40, 0x40, 0x40, 0x40}, // 'L' (76)
    {0x7F, 0x02, 0x0C, 0x02, 0x7F}, // 'M' (77)
    {0x7F, 0x04, 0x08, 0x10, 0x7F}, // 'N' (78)
    {0x3E, 0x41, 0x41, 0x41, 0x3E}, // 'O' (79)
    {0x7F, 0x09, 0x09, 0x09, 0x06}, // 'P' (80)
    {0x3E, 0x41, 0x51, 0x21, 0x5E}, // 'Q' (81)
    {0x7F, 0x09, 0x19, 0x29, 0x46}, // 'R' (82)
    {0x46, 0x49, 0x49, 0x49, 0x31}, // 'S' (83)
    {0x01, 0x01, 0x7F, 0x01, 0x01}, // 'T' (84)
    {0x3F, 0x40, 0x40, 0x40, 0x3F}, // 'U' (85)
    {0x1F, 0x20, 0x40, 0x20, 0x1F}, // 'V' (86)
    {0x3F, 0x40, 0x38, 0x40, 0x3F}, // 'W' (87)
    {0x63, 0x14, 0x08, 0x14, 0x63}, // 'X' (88)
    {0x07, 0x08, 0x70, 0x08, 0x07}, // 'Y' (89)
    {0x61, 0x51, 0x49, 0x45, 0x43}, // 'Z' (90)
    {0x00, 0x7F, 0x41, 0x41, 0x00}, // '[' (91)
    {0x02, 0x04, 0x08, 0x10, 0x20}, // '\' (92)
    {0x00, 0x41, 0x41, 0x7F, 0x00}, // ']' (93)
    {0x04, 0x02, 0x01, 0x02, 0x04}, // '^' (94)
    {0x40, 0x40, 0x40, 0x40, 0x40}, // '_' (95)
    {0x00, 0x01, 0x02, 0x04, 0x00}, // '`' (96)
    {0x20, 0x54, 0x54, 0x54, 0x78}, // 'a' (97)
    {0x7F, 0x48, 0x44, 0x44, 0x38}, // 'b' (98)
    {0x38, 0x44, 0x44, 0x44, 0x20}, // 'c' (99)
    {0x38, 0x44, 0x44, 0x48, 0x7F}, // 'd' (100)
    {0x38, 0x54, 0x54, 0x54, 0x18}, // 'e' (101)
    {0x08, 0x7E, 0x09, 0x01, 0x02}, // 'f' (102)
    {0x0C, 0x52, 0x52, 0x52, 0x3E}, // 'g' (103)
    {0x7F, 0x08, 0x04, 0x04, 0x78}, // 'h' (104)
    {0x00, 0x44, 0x7D, 0x40, 0x00}, // 'i' (105)
    {0x20, 0x40, 0x44, 0x3D, 0x00}, // 'j' (106)
    {0x7F, 0x10, 0x28, 0x44, 0x00}, // 'k' (107)
    {0x00, 0x41, 0x7F, 0x40, 0x00}, // 'l' (108)
    {0x7C, 0x04, 0x18, 0x04, 0x78}, // 'm' (109)
    {0x7C, 0x08, 0x04, 0x04, 0x78}, // 'n' (110)
    {0x38, 0x44, 0x44, 0x44, 0x38}, // 'o' (111)
    {0x7C, 0x14, 0x14, 0x14, 0x08}, // 'p' (112)
    {0x08, 0x14, 0x14, 0x18, 0x7C}, // 'q' (113)
    {0x7C, 0x08, 0x04, 0x04, 0x08}, // 'r' (114)
    {0x48, 0x54, 0x54, 0x54, 0x20}, // 's' (115)
    {0x04, 0x3F, 0x44, 0x40, 0x20}, // 't' (116)
    {0x3C, 0x40, 0x40, 0x20, 0x7C}, // 'u' (117)
    {0x1C, 0x20, 0x40, 0x20, 0x1C}, // 'v' (118)
    {0x3C, 0x40, 0x30, 0x40, 0x3C}, // 'w' (119)
    {0x44, 0x28, 0x10, 0x28, 0x44}, // 'x' (120)
    {0x0C, 0x50, 0x50, 0x50, 0x3C}, // 'y' (121)
    {0x44, 0x64, 0x54, 0x4C, 0x44}, // 'z' (122)
    {0x00, 0x08, 0x36, 0x41, 0x00}, // '{' (123)
    {0x00, 0x00, 0x7F, 0x00, 0x00}, // '|' (124)
    {0x00, 0x41, 0x36, 0x08, 0x00}, // '}' (125)
    {0x08, 0x04, 0x08, 0x10, 0x08}, // '~' (126)
    {0x00, 0x06, 0x09, 0x09, 0x06}  // DEL (127)
};

/** @def SSD1351_WIDTH
 *  @brief Breite des SSD1351 Displays in Pixel.
 */
#define SSD1351_WIDTH 128
/** @def SSD1351_HEIGHT
 *  @brief Höhe des SSD1351 Displays in Pixel.
 */
#define SSD1351_HEIGHT 128
/** @def CHAR_WIDTH
 *  @brief Breite eines Zeichens in Pixel.
 */
#define CHAR_WIDTH 6
/** @def CHAR_HEIGHT
 *  @brief Höhe eines Zeichens in Pixel.
 */
#define CHAR_HEIGHT 8
/** @def STATUS_BAR_ROWS
 *  @brief Anzahl der Zeilen für die Statusleiste.
 */
#define STATUS_BAR_ROWS 1
/** @def TOTAL_ROWS
 *  @brief Gesamte Anzahl der Textzeilen auf dem Display.
 */
#define TOTAL_ROWS (SSD1351_HEIGHT / CHAR_HEIGHT)
/** @def TERM_COLS
 *  @brief Anzahl der Spalten im Terminal.
 */
#define TERM_COLS (SSD1351_WIDTH / CHAR_WIDTH)
/** @def TERM_ROWS
 *  @brief Anzahl der Zeilen im Terminal.
 */
#define TERM_ROWS (TOTAL_ROWS)
/** @def SSD1351_SPI_TIMEOUT
 *  @brief SPI-Zeitlimit in Millisekunden für das Display.
 */
#define SSD1351_SPI_TIMEOUT 10
/** @def HOUSEKEEPING_MS
 *  @brief Intervall für Display-Housekeeping in Millisekunden.
 */
#define HOUSEKEEPING_MS 250

/** @def COLOR_BLACK
 *  @brief Farbe: Schwarz.
 */
#define COLOR_BLACK 0x0000
/** @def COLOR_WHITE
 *  @brief Farbe: Weiß.
 */
#define COLOR_WHITE 0xFFFF
/** @def COLOR_RED
 *  @brief Farbe: Rot.
 */
#define COLOR_RED 0x07E0
/** @def COLOR_GREEN
 *  @brief Farbe: Grün.
 */
#define COLOR_GREEN 0xF800
/** @def COLOR_BLUE
 *  @brief Farbe: Blau.
 */
#define COLOR_BLUE 0x001F
/** @def COLOR_YELLOW
 *  @brief Farbe: Gelb.
 */
#define COLOR_YELLOW 0xFFE0
/** @def COLOR_MAGENTA
 *  @brief Farbe: Magenta.
 */
#define COLOR_MAGENTA 0xF81F
/** @def COLOR_CYAN
 *  @brief Farbe: Cyan.
 */
#define COLOR_CYAN 0x07FF

/**
 * @brief Führt periodische Wartungsarbeiten am SSD1351 Display durch (z.B. Cursor-Blinken).
 */
void housekeeping(void);

/**
 * @brief Schaltet den Invertierungsmodus des Displays um.
 */
void ssd1351_inv(void);

/**
 * @brief Sendet einen Datenpuffer an das SSD1351 Display.
 *
 * @param data Zeiger auf den Datenpuffer.
 * @param len Länge des Puffers in Byte.
 */
void ssd1351_send_data(const uint8_t *data, size_t len);

/**
 * @brief Sendet einen einzelnen Befehl an das SSD1351 Display.
 *
 * @param cmd Befehlscode.
 */
void ssd1351_send_command(uint8_t cmd);

/**
 * @brief Sendet einen Befehl mit zugehörigen Daten an das SSD1351 Display.
 *
 * @param cmd Befehlscode.
 * @param data Zeiger auf den Datenpuffer.
 * @param len Länge der Daten in Byte.
 */
void ssd1351_send_command_with_data(uint8_t cmd, const uint8_t *data, size_t len);

/**
 * @brief Sendet eine Folge von Befehlen an das SSD1351 Display.
 *
 * @param buf Zeiger auf den Befehlsbuffer.
 * @param len Länge des Buffers in Byte.
 */
void ssd1351_send_commands(const uint8_t *buf, size_t len);

/**
 * @brief Initialisiert das SSD1351 Display.
 */
void ssd1351_init(void);

/**
 * @brief Setzt die Schreibposition und den Bereich im SSD1351 Display.
 *
 * @param x Startspalte.
 * @param y Startzeile.
 * @param w Breite des Bereichs.
 * @param h Höhe des Bereichs.
 */
void ssd1351_set_position(uint8_t x, uint8_t y, uint8_t w, uint8_t h);

/**
 * @brief Füllt das gesamte Display mit einer Farbe.
 *
 * @param color Zu füllende Farbe.
 */
void ssd1351_fill_screen(uint16_t color);

/**
 * @brief Zeichnet einen einzelnen Pixel an einer bestimmten Position.
 *
 * @param x X-Koordinate.
 * @param y Y-Koordinate.
 * @param color Farbe des Pixels.
 */
void ssd1351_draw_pixel(uint8_t x, uint8_t y, uint16_t color);

/**
 * @brief Initialisiert das Terminal (Display) des SSD1351.
 */
void terminal_init(void);

/**
 * @brief Gibt einen String im Terminal aus.
 *
 * @param str Zu druckender String.
 */
void terminal_print(const char *str);

/**
 * @brief Gibt einen String im Terminal mit einer bestimmten Textfarbe aus.
 *
 * @param text Zu druckender String.
 * @param color Textfarbe.
 */
void terminal_print_col(const char *text, uint16_t color);

/**
 * @brief Gibt ein Label und einen numerischen Wert (als String) aus, farblich als OK markiert.
 *
 * @param label Beschriftung.
 * @param value Numerischer Wert.
 */
void print_ok_res(const char *label, int32_t value);

/**
 * @brief Gibt ein Label als OK-Nachricht aus.
 *
 * @param label Beschriftung.
 */
void print_ok(const char *label);

/**
 * @brief Gibt ein Label als Fehlernachricht aus.
 *
 * @param label Beschriftung.
 */
void print_error(const char *label);

/**
 * @brief Gibt ein einzelnes Zeichen im Terminal aus und aktualisiert den Cursor.
 *
 * @param c Zu druckendes Zeichen.
 */
void terminal_put_char(char c);

/**
 * @brief Setzt die Textfarbe des Terminals.
 *
 * @param color Neue Textfarbe.
 */
void terminal_set_text_color(uint16_t color);

/**
 * @brief Setzt die Hintergrundfarbe des Terminals.
 *
 * @param color Neue Hintergrundfarbe.
 */
void terminal_set_bg_color(uint16_t color);

/**
 * @brief Zeichnet einen Text an einer bestimmten Terminalposition mit definierten Vorder- und Hintergrundfarben.
 *
 * @param row Zeile.
 * @param col Spalte.
 * @param str Zu zeichnender Text.
 * @param fg_color Vordergrundfarbe.
 * @param bg_color Hintergrundfarbe.
 */
void terminal_draw_text(uint8_t row, uint8_t col, const char *str, uint16_t fg_color, uint16_t bg_color);

/**
 * @brief Zeichnet einen Text an einer bestimmten Terminalposition mit Standardfarben.
 *
 * @param row Zeile.
 * @param col Spalte.
 * @param str Zu zeichnender Text.
 */
void terminal_draw_text_default(uint8_t row, uint8_t col, const char *str);

/**
 * @brief Scrollt das Terminal um eine Zeile.
 */
void terminal_native_scroll(void);

/**
 * @brief Löscht eine bestimmte Terminalzeile.
 *
 * @param row Zu löschende Zeile.
 */
void clear_terminal_row(uint8_t row);

/**
 * @brief Löscht das gesamte Terminal.
 */
void clear_terminal(void);

/**
 * @brief Zeichnet eine Statusleiste am oberen Displayrand.
 *
 * @param text Anzuzeigender Text.
 * @param bg_color Hintergrundfarbe.
 * @param fg_color Textfarbe.
 */
void draw_status_bar(const char *text, uint16_t bg_color, uint16_t fg_color);

/**
 * @brief Zeichnet ein einzelnes Zeichen in einer Terminalzelle.
 *
 * @param row Zeile.
 * @param col Spalte.
 * @param c Zu zeichnendes Zeichen.
 */
void draw_char_cell(uint8_t row, uint8_t col, char c);

/**
 * @brief Zeichnet ein einzelnes Zeichen in einer Terminalzelle mit individuellen Farben.
 *
 * @param row Zeile.
 * @param col Spalte.
 * @param c Zu zeichnendes Zeichen.
 * @param fg Vordergrundfarbe.
 * @param bg Hintergrundfarbe.
 */
void draw_char_cell_custom(uint8_t row, uint8_t col, char c, uint16_t fg, uint16_t bg);

/**
 * @brief Gibt die aktuelle X-Position des Cursors im SSD1351 Terminal zurück.
 *
 * @return X-Koordinate des Cursors.
 */
uint32_t ssd1351_cursor_x(void);

#endif

#endif /* WGRHAL_EXT_H */
