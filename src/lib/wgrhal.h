/**
 * @file wgrhal.h
 * @brief Headerdatei der WGRHAL-Bibliothek.
 *
 * Diese Datei enthält Definitionen und Deklarationen für Standard-Memory-Funktionen, String-Funktionen,
 * Debug-Ausgaben, UART, Zeitfunktionen, PWM und GPIO für den WGR-V-Prozessor.
 */

#ifndef WGRHAL_H
#define WGRHAL_H

#define MALLOC
#define PWM_NOTES
#define SSD1351

#include "wgrtypes.h"

/** @def SYSTEM_CLOCK
 *  @brief Definiert die Systemtaktfrequenz in Hertz.
 */
#define SYSTEM_CLOCK 10000000

/** @def HWREG32
 *  @brief Makro zur Adressierung von speicherabgebildeten Registern.
 */
#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

/** @def nop()
 *  @brief Nop-Operation.
 */
#define nop()  __asm__ volatile("nop")

/** @def DEBUG_ADDR
 *  @brief Basisadresse für das Debug-Register.
 */
#define DEBUG_ADDR 0x00000100

/** @def UART_BASE_ADDR
 *  @brief Basisadresse für den UART.
 */
#define UART_BASE_ADDR 0x00000200
/** @def UART_CTRL_OFFSET
 *  @brief Offset für das UART-Steuerregister.
 */
#define UART_CTRL_OFFSET 0x00
/** @def UART_BAUD_OFFSET
 *  @brief Offset für das UART-Baudratenregister.
 */
#define UART_BAUD_OFFSET 0x04
/** @def UART_STATUS_OFFSET
 *  @brief Offset für das UART-Statusregister.
 */
#define UART_STATUS_OFFSET 0x08
/** @def UART_TX_OFFSET
 *  @brief Offset für das UART-Sende-Register.
 */
#define UART_TX_OFFSET 0x0C
/** @def UART_RX_OFFSET
 *  @brief Offset für das UART-Empfangsregister.
 */
#define UART_RX_OFFSET 0x10

/** @def TIME_BASE_ADDR
 *  @brief Basisadresse für Zeitfunktionen.
 */
#define TIME_BASE_ADDR 0x00000300
/** @def TIME_MS_L_OFFSET
 *  @brief Offset für die niederwertigen 32-Bit des Millisekundenzählers.
 */
#define TIME_MS_L_OFFSET 0x00
/** @def TIME_MS_H_OFFSET
 *  @brief Offset für die höheren 32-Bit des Millisekundenzählers.
 */
#define TIME_MS_H_OFFSET 0x04
/** @def TIME_MIK_L_OFFSET
 *  @brief Offset für die niederwertigen 32-Bit des Mikrosekundenzählers.
 */
#define TIME_MIK_L_OFFSET 0x08
/** @def TIME_MIK_H_OFFSET
 *  @brief Offset für die höheren 32-Bit des Mikrosekundenzählers.
 */
#define TIME_MIK_H_OFFSET 0x0C
/** @def SYS_CLK_OFFSET
 *  @brief Offset für den Systemtakt.
 */
#define SYS_CLK_OFFSET 0x10

/** @def PWM_BASE_ADDR
 *  @brief Basisadresse für PWM-Funktionen.
 */
#define PWM_BASE_ADDR 0x00000400
/** @def PWM_PERIOD_OFFSET
 *  @brief Offset für das PWM-Periode-Register.
 */
#define PWM_PERIOD_OFFSET 0x00
/** @def PWM_DUTY_OFFSET
 *  @brief Offset für das PWM-Duty-Cycle-Register.
 */
#define PWM_DUTY_OFFSET 0x04
/** @def PWM_COUNTER_OFFSET
 *  @brief Offset für das PWM-Zählerregister.
 */
#define PWM_COUNTER_OFFSET 0x08
/** @def PWM_CTRL_OFFSET
 *  @brief Offset für das PWM-Steuerregister.
 */
#define PWM_CTRL_OFFSET 0x0C

/** @def GPIO_BASE_ADDR
 *  @brief Basisadresse für GPIO-Funktionen.
 */
#define GPIO_BASE_ADDR 0x00000800
/** @def GPIO_DIR_OFFSET
 *  @brief Offset für das GPIO-Richtungsregister.
 */
#define GPIO_DIR_OFFSET 0x0000
/** @def GPIO_IN_OFFSET
 *  @brief Offset für das GPIO-Eingangsregister.
 */
#define GPIO_IN_OFFSET 0x0004
/** @def GPIO_OUT_OFFSET
 *  @brief Offset für das GPIO-Ausgangsregister.
 */
#define GPIO_OUT_OFFSET 0x0008
/** @def GPIO_OUT_STEP
 *  @brief Schrittweite zwischen den Ausgangsregistern der einzelnen Pins.
 */
#define GPIO_OUT_STEP 0x04
/** @def GPIO_PIN_COUNT
 *  @brief Anzahl der verfügbaren GPIO-Pins.
 */
#define GPIO_PIN_COUNT 8

/** @def DEFAULT_TIMEOUT
 *  @brief Standard-Zeitüberschreitung in Millisekunden.
 */
#define DEFAULT_TIMEOUT 10

/* Standard Memory Functions */
/**
 * @brief Kopiert n Bytes von src nach dest.
 *
 * @param dest Zielpuffer, in den die Bytes kopiert werden.
 * @param src Quellpuffer, von dem die Bytes gelesen werden.
 * @param n Anzahl der zu kopierenden Bytes.
 * @return Zeiger auf den Zielpuffer.
 */
void *memcpy(void *dest, const void *src, uint32_t n);

/**
 * @brief Setzt n Bytes im Zielpuffer auf den Wert c.
 *
 * @param dest Zielpuffer, in dem der Wert gesetzt wird.
 * @param c Zu setzender Wert.
 * @param n Anzahl der Bytes, die gesetzt werden.
 * @return Zeiger auf den Zielpuffer.
 */
void *memset(void *dest, int32_t c, uint32_t n);

/**
 * @brief Kopiert n Bytes von src nach dest, wobei sich überlappende Speicherbereiche korrekt behandelt werden.
 *
 * @param dest Zielpuffer.
 * @param src Quellpuffer.
 * @param n Anzahl der zu kopierenden Bytes.
 * @return Zeiger auf den Zielpuffer.
 */
void *memmove(void *dest, const void *src, uint32_t n);

/* Standard String Functions */
/**
 * @brief Bestimmt die Länge eines Strings.
 *
 * @param s Zeiger auf den Null-terminierten String.
 * @return Länge des Strings ohne das Nullzeichen.
 */
uint32_t strlen(const char *s);

/**
 * @brief Vergleicht zwei Strings.
 *
 * @param s1 Erster String.
 * @param s2 Zweiter String.
 * @return Differenz der ersten unterschiedlichen Zeichen, oder 0, wenn die Strings gleich sind.
 */
int32_t strcmp(const char *s1, const char *s2);

/**
 * @brief Vergleicht maximal n Zeichen zweier Strings.
 *
 * @param s1 Erster String.
 * @param s2 Zweiter String.
 * @param n Maximale Anzahl zu vergleichender Zeichen.
 * @return 0, wenn die ersten n Zeichen gleich sind, sonst Differenz der ersten unterschiedlichen Zeichen.
 */
int32_t strncmp(const char *s1, const char *s2, uint32_t n);

/**
 * @brief Kopiert einen String von src nach dest.
 *
 * @param dest Zielpuffer, in den der String kopiert wird.
 * @param src Quellstring.
 * @return Zeiger auf den Zielpuffer.
 */
char *strcpy(char *dest, const char *src);

/**
 * @brief Konvertiert eine Ganzzahl in einen String.
 *
 * @param num Zu konvertierende Zahl.
 * @param base Zahlensystembasis (zwischen 2 und 16).
 * @param str Zielpuffer, in dem der resultierende String gespeichert wird.
 */
void int_to_str(int32_t num, int base, char *str);

/**
 * @brief Parst einen String in eine Ganzzahl.
 *
 * @param str Zu parsender String.
 * @return Die geparste Ganzzahl oder -1 bei Fehler.
 */
int32_t parse_integer(const char *str);

/**
 * @brief Parst eine Ganzzahl aus einem String und gibt den Zeiger auf das nächste Zeichen zurück.
 *
 * @param str Zu parsender String.
 * @param next Zeiger auf den Reststring nach der Ganzzahl.
 * @return Die geparste Ganzzahl oder -1 bei Fehler.
 */
int32_t parse_int_multi(const char *str, const char **next);

/* Writing to Debug Register */
/**
 * @brief Schreibt einen Wert in das Debug-Register.
 *
 * @param value Zu schreibender Wert.
 */
void debug_write(uint32_t value);

/* UART Functions */
/**
 * @brief Aktiviert die UART-Schnittstelle.
 */
void uart_enable(void);

/**
 * @brief Deaktiviert die UART-Schnittstelle.
 */
void uart_disable(void);

/**
 * @brief Setzt die Baudrate der UART-Schnittstelle.
 *
 * @param baud Auswahl der Baudrate (baud_sel_t).
 */
void uart_set_baud(baud_sel_t baud);

/**
 * @brief Liest den Status der UART-Schnittstelle.
 *
 * @return Statuswert der UART.
 */
uint32_t uart_get_status(void);

/**
 * @brief Prüft, ob die UART bereit ist.
 *
 * @return 1, wenn bereit, sonst 0.
 */
uint32_t uart_is_ready(void);

/**
 * @brief Prüft, ob die UART beschäftigt ist.
 *
 * @return 1, wenn beschäftigt, sonst 0.
 */
uint32_t uart_is_busy(void);

/**
 * @brief Prüft, ob der UART-Empfangspuffer voll ist.
 *
 * @return 1, wenn voll, sonst 0.
 */
uint32_t uart_rx_full(void);

/**
 * @brief Prüft, ob der UART-Empfangspuffer leer ist.
 *
 * @return 1, wenn leer, sonst 0.
 */
uint32_t uart_rx_empty(void);

/**
 * @brief Prüft, ob der UART-Sende-Puffer voll ist.
 *
 * @return 1, wenn voll, sonst 0.
 */
uint32_t uart_tx_full(void);

/**
 * @brief Prüft, ob der UART-Sende-Puffer leer ist.
 *
 * @return 1, wenn leer, sonst 0.
 */
uint32_t uart_tx_empty(void);

/**
 * @brief Wartet darauf, dass der Sende-Puffer voll wird, bis zu einer Zeitüberschreitung.
 *
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Zeitüberschreitung.
 */
int32_t uart_wait_tx_full(uint32_t timeout_ms);

/**
 * @brief Wartet darauf, dass Daten im Empfangspuffer vorhanden sind, bis zu einer Zeitüberschreitung.
 *
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Zeitüberschreitung.
 */
int32_t uart_wait_rx_data(uint32_t timeout_ms);

/**
 * @brief Sendet ein Byte über die UART-Schnittstelle.
 *
 * @param data Zu sendendes Byte.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t uart_write_byte(uint8_t data, uint32_t timeout_ms);

/**
 * @brief Sendet ein Zeichen über die UART-Schnittstelle.
 *
 * @param c Zu sendendes Zeichen.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t uart_putchar(char c, uint32_t timeout_ms);

/**
 * @brief Sendet ein Zeichen über die UART-Schnittstelle mit voreingestelltem Timeout.
 *
 * @param c Zu sendendes Zeichen.
 */
void uart_putchar_default_timeout(char c);

/**
 * @brief Sendet einen Puffer von Bytes über die UART-Schnittstelle.
 *
 * @param buffer Zeiger auf den zu sendenden Datenpuffer.
 * @param length Anzahl der zu sendenden Bytes.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t uart_write_buffer(const uint8_t *buffer, uint32_t length, uint32_t timeout_ms);

/**
 * @brief Liest ein Byte von der UART-Schnittstelle.
 *
 * @param data Zeiger, in den das gelesene Byte gespeichert wird.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t uart_read_byte(uint8_t *data, uint32_t timeout_ms);

/**
 * @brief Liest ein Zeichen von der UART-Schnittstelle.
 *
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return Gelesenes Zeichen oder -1 bei Fehler.
 */
char uart_getchar(uint32_t timeout_ms);

/**
 * @brief Liest einen Puffer von Bytes von der UART-Schnittstelle.
 *
 * @param buf Zielpuffer für die gelesenen Bytes.
 * @param length Anzahl der zu lesenden Bytes.
 * @param timeout_ms Zeitlimit in Millisekunden.
 * @return 0 bei Erfolg, -1 bei Fehler.
 */
int32_t uart_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms);

/**
 * @brief Sendet einen 32-Bit-Wert über die UART-Schnittstelle.
 *
 * @param value Zu sendender Wert.
 * @param timeout_ms Zeitlimit in Millisekunden.
 */
void uart_send_uint32(uint32_t value, uint32_t timeout_ms);

/**
 * @brief Gibt eine positive Ganzzahl in einem bestimmten Zahlensystem über die UART aus.
 *
 * @param num Zu druckende Zahl.
 * @param base Zahlensystembasis.
 */
void uart_print_uint(uint32_t num, int32_t base);

/**
 * @brief Gibt eine Ganzzahl über die UART aus.
 *
 * @param num Zu druckende Zahl.
 */
void uart_print_int(int32_t num);

/**
 * @brief Gibt einen String über die UART aus.
 *
 * @param s Zu druckender String.
 */
void uart_print(const char *s);

/* Time Functions */
/**
 * @brief Liest die Systemtaktfrequenz.
 *
 * @return Systemtakt in Hertz.
 */
uint32_t get_sys_clk(void);

/**
 * @brief Setzt den Millisekunden-Zähler zurück.
 */
void millis_reset(void);

/**
 * @brief Liest einen langen Millisekunden-Zähler.
 *
 * @return 64-Bit Millisekunden-Zähler.
 */
uint64_t millis_long(void);

/**
 * @brief Liest den aktuellen Millisekunden-Zähler (32-Bit).
 *
 * @return Millisekunden-Zähler.
 */
uint32_t millis(void);

/**
 * @brief Setzt den Mikrosekunden-Zähler zurück.
 */
void micros_reset(void);

/**
 * @brief Liest einen langen Mikrosekunden-Zähler.
 *
 * @return 64-Bit Mikrosekunden-Zähler.
 */
uint64_t micros_long(void);

/**
 * @brief Liest den aktuellen Mikrosekunden-Zähler (32-Bit).
 *
 * @return Mikrosekunden-Zähler.
 */
uint32_t micros(void);

/**
 * @brief Verzögert die Ausführung um eine bestimmte Anzahl an Millisekunden.
 *
 * @param ms Anzahl der Millisekunden.
 */
void delay(uint32_t ms);

/**
 * @brief Verzögert die Ausführung um eine bestimmte Anzahl an Mikrosekunden.
 *
 * @param microsec Anzahl der Mikrosekunden.
 */
void delay_micro(uint32_t microsec);

/* PWM Functions */
/**
 * @brief Setzt die PWM-Periode.
 *
 * @param period Neue Periode.
 */
void pwm_set_period(uint32_t period);

/**
 * @brief Setzt das PWM-Duty-Cycle.
 *
 * @param duty Neuer Duty-Cycle.
 */
void pwm_set_duty(uint32_t duty);

/**
 * @brief Liest die aktuelle PWM-Periode.
 *
 * @return Aktuelle Periode.
 */
uint32_t pwm_get_period(void);

/**
 * @brief Liest das aktuelle PWM-Duty-Cycle.
 *
 * @return Aktueller Duty-Cycle.
 */
uint32_t pwm_get_duty(void);

/**
 * @brief Liest den aktuellen PWM-Zählerstand.
 *
 * @return Aktueller Zählerstand.
 */
uint32_t pwm_get_counter(void);

/**
 * @brief Setzt den PWM-Kontrollwert.
 *
 * @param control Neuer Kontrollwert.
 */
void pwm_set_control(uint32_t control);

/**
 * @brief Liest den aktuellen PWM-Kontrollwert.
 *
 * @return Aktueller Kontrollwert.
 */
uint32_t pwm_get_control(void);

/**
 * @brief Aktiviert oder deaktiviert den PWM-Modus.
 *
 * @param enable_pwm 1 zum Aktivieren, 0 zum Deaktivieren.
 */
void pwm_set_mode(uint8_t enable_pwm);

/**
 * @brief Liest den aktuellen PWM-Modus.
 *
 * @return 1 wenn aktiviert, sonst 0.
 */
uint32_t pwm_get_mode(void);

/**
 * @brief Aktiviert oder deaktiviert den 50%-Modus des PWM.
 *
 * @param enable 1 zum Aktivieren, 0 zum Deaktivieren.
 */
void pwm_set_50_percent_mode(uint8_t enable);

/**
 * @brief Setzt den Pre-Counter für PWM.
 *
 * @param pre_counter Neuer Pre-Counter-Wert.
 */
void pwm_set_pre_counter(uint16_t pre_counter);

/**
 * @brief Liest den aktuellen Pre-Counter für PWM.
 *
 * @return Aktueller Pre-Counter-Wert.
 */
uint32_t pwm_get_pre_counter(void);

/* GPIO Functions */
/**
 * @brief Schreibt einen Wert auf einen GPIO-Pin.
 *
 * @param pin Pin-Nummer.
 * @param value Zu schreibender Wert.
 */
void gpio_write_pin(uint8_t pin, uint8_t value);

/**
 * @brief Liest alle GPIO-Pins.
 *
 * @return 8-Bit Wert aller Pins.
 */
uint8_t gpio_read_all_pins(void);

/**
 * @brief Liest den Zustand eines bestimmten GPIO-Pins.
 *
 * @param pin Pin-Nummer.
 * @return Zustand des Pins (0 oder 1).
 */
uint8_t gpio_read_pin(uint8_t pin);

/**
 * @brief Setzt die Richtung eines GPIO-Pins.
 *
 * @param pin Pin-Nummer.
 * @param direction Richtung (1 für Ausgang, 0 für Eingang).
 */
void gpio_set_direction(uint8_t pin, uint8_t direction);

/**
 * @brief Liest die Richtung eines GPIO-Pins.
 *
 * @param pin Pin-Nummer.
 * @return Richtung des Pins (1 für Ausgang, 0 für Eingang).
 */
uint8_t gpio_read_direction(uint8_t pin);

#endif /* WGRHAL_H */
