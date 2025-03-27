`ifndef DEFINES_V
`define DEFINES_V

/**
 * @brief Globale Definitionsdatei (Makros und Parameter).
 *
 * Diese Datei definiert verschiedene globale Konstante, Parameter und Makros,
 * die in den restlichen Modulen verwendet werden. Sie legt unter anderem
 * die Taktfrequenz (`CLK_FREQ`), UART- und SPI-FIFO-Größen fest, sowie
 * Flags zum Bedingten Integrieren bestimmter Module (z. B. `INCLUDE_UART`).
 */

/**
 * @macro CLK_FREQ
 * Gibt die Taktfrequenz des Systems in Hz an, z. B. 12 MHz.
 */
`define CLK_FREQ       12_000_000

/**
 * @macro BAUD_DIV(Baud)
 * Berechnet den Teilerwert für eine angegebene Baudrate. 
 * Beispiel: `BAUD_DIV(115200)` bei 12 MHz ergibt den passenden Teilwert.
 */
`define BAUD_DIV(Baud) ((`CLK_FREQ / Baud) - 1)

/**
 * @macro RV32I
 * Aktiviert (falls definiert) den Betrieb als 32-Bit RISC-V-Kern.
 */
`define RV32I

/**
 * @macro FRAM_MEMORY
 * Aktiviert (falls definiert) die Verwendung des FRAM-Speichers statt internem RAM.
 */
//`define FRAM_MEMORY

/**
 * @macro UART_FIFO_TX_DEPTH
 * @macro UART_FIFO_RX_DEPTH
 * Legt die Tiefe (Anzahl Einträge) für die TX- und RX-FIFOs des UART fest.
 */
`define UART_FIFO_TX_DEPTH 4
`define UART_FIFO_RX_DEPTH 4

/**
 * @macro SPI_FIFO_TX_DEPTH
 * @macro SPI_FIFO_RX_DEPTH
 * Legt die Tiefe (Anzahl Einträge) für die TX- und RX-FIFOs des SPI fest.
 */
`define SPI_FIFO_TX_DEPTH 4
`define SPI_FIFO_RX_DEPTH 4

/**
 * @macro INCLUDE_DEBUG, INCLUDE_UART, INCLUDE_TIME, ...
 * Schalter zum bedingten Einbinden der jeweiligen Peripheriemodule.
 */
`define INCLUDE_DEBUG
`define INCLUDE_UART
`define INCLUDE_TIME
`define INCLUDE_PWM
`define INCLUDE_MULT
`define INCLUDE_DIV
`define INCLUDE_SPI
`define INCLUDE_GPIO
`define INCLUDE_WS

`endif
