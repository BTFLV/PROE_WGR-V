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
 * @brief Gibt die Taktfrequenz des Systems in Hz an, z. B. 12 MHz.
 * @macro CLK_FREQ
 */
`define CLK_FREQ       12_000_000

/**
 * @brief Berechnet den Teilerwert für eine angegebene Baudrate. 
 *        Beispiel: `BAUD_DIV(115200)` bei 12 MHz ergibt den passenden Teilwert.
 * @macro BAUD_DIV(Baud)
 */
`define BAUD_DIV(Baud) ((`CLK_FREQ / Baud) - 1)

/**
 * @brief Aktiviert (falls definiert) den Betrieb als 32-Bit RISC-V-Kern.
 * @macro RV32I
 */
`define RV32I

/**
 * @brief Aktiviert (falls definiert) die Verwendung des FRAM-Speichers statt internem RAM.
 * @macro FRAM_MEMORY
 */
//`define FRAM_MEMORY

/**
 * @brief Legt die Tiefe (Anzahl Einträge) für die TX- und RX-FIFOs des UART fest.
 * @macro UART_FIFO_TX_DEPTH
 * @macro UART_FIFO_RX_DEPTH
 */
`define UART_FIFO_TX_DEPTH 4
`define UART_FIFO_RX_DEPTH 4

/**
 * @brief Legt die Tiefe (Anzahl Einträge) für die TX- und RX-FIFOs des SPI fest.
 * @macro SPI_FIFO_TX_DEPTH
 * @macro SPI_FIFO_RX_DEPTH
 */
`define SPI_FIFO_TX_DEPTH 4
`define SPI_FIFO_RX_DEPTH 4

/**
 * @brief Schalter zum bedingten Einbinden der jeweiligen Peripheriemodule.
 * @macro INCLUDE_DEBUG, INCLUDE_UART, INCLUDE_TIME, ...
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
