/**
 * Provides mechanisms for encoding market tick data into a compressed binary 
 * format for storage in files or databases.
 * <p>
 * The functionality is provided by two interfaces, 
 * {@link com.tradewright.tradebuild.tickutils.TickDataEncoder TickDataEncoder} and
 * {@link com.tradewright.tradebuild.tickutils.TickDataDecoder TickDataDecoder}, 
 * together with a pair of static factory methods that create instances of classes that 
 * implement these interfaces - these methods are
 * {@link com.tradewright.tradebuild.tickutils.TickUtils#getTickEncoder getTickEncoder} and 
 * {@link com.tradewright.tradebuild.tickutils.TickUtils#getTickDecoder getTickDecoder}.
 *
 * <p>
 * The encoding used places strict limits on the time span covered by an encoder: this 
 * is because tick times are recorded as a number of milliseconds from the start of the 
 * encoding period, and these values are recorded as 16-bit unsigned integers: the maximum 
 * timespan is therefore 65535 millseconds. Once this limit has been reached, the encoded
 * data must be retrieved from the encoder and written to storage, and a new encoder must 
 * then be created.  The expectation is that tick data recording programs will limit 
 * individual stored segments of encoded data to an interval such as 30 seconds or 1 minute, 
 * and that these segments will be stored in a variable length container such as a BLOB 
 * (Binary Large Object) column in a database row.
 *
 * <p>
 * To summarise the use of this component:
 *
 * <h4>Encoding</h4>
 *
 * 1. At the start of each encoding interval (say at the start of each minute or each 30 seconds,
 * but not longer than one minute), create a new encoder object by calling
 * {@link com.tradewright.tradebuild.tickutils.TickUtils#getTickEncoder getTickEncoder}.
 *
 * <p>
 * 2. As each tick arrives, encode it by calling the appropriate method of the encoder object,
 * depending on the type of tick.
 *
 * <p>
 * 3. At the end of the encoding period, obtain from the encoder object the base price, the
 * encoded data and the encoding format identifier, and write these to your data store along
 * with the period start time and the ticksize. Then discard the existing encoder object,
 * and return to step 1.
 *
 * <h4>Decoding</h4>
 *
 * 1. Retrieve from your data store the encoded data, and the corresponding period start time,
 * base price, tick size and encoding format identifier.
 *
 * <p>
 * 2. Create a new decoder object using the 
 * {@link com.tradewright.tradebuild.tickutils.TickUtils#getTickDecoder getTickDecoder} method.
 *
 * <p>
 * 3. Extract the next tick from the decoder by calling its 
 * {@link com.tradewright.tradebuild.tickutils.TickDataDecoder#getNextTick getNextTick} method.
 *
 * <p>
 * 4. Process the tick as required by your program.
 *
 * <p>
 * 5. Repeat from step 3 until <code>getNextTick</code> indicates that there are no further
 * ticks.
 *
 * <h2>Encoding format</h2>
 * Details of the encoding scheme are provided here for completeness, and to enable developers
 * to produce compatible software in other languages.
 *
 * <p>
 * No understanding of the encoding scheme is necessary to use this software.
 *
 * <p>
 * The encoding format identifier for this encoding scheme is this URN:
 * <p>
 *  urn:uid:b61df8aa-d8cc-47b1-af18-de725dee0ff5
 * <p>
 * Future enhancements to this encoding scheme, or different encoding schemes, will have
 * different encoding format identifiers.
 * <p>
 * An encoded data segment is a byte array, consisting of a series of variable-length records. Each
 * record encodes a single tick.
 * <p>
 * A record consists of an initial byte, called the type byte, followed by zero or more fields 
 * containing the tick's attributes. The fields included in any particular record depend on the 
 * type of the tick encoded in the record. The following types of field are defined:
 * <pre>
 *      Timestamp field
 *      Price field
 *      Size field
 *      Side/operation/position field
 *      Marketmaker field
 * </pre>
 *
 * Ask ticks, bid ticks, and trade ticks contain the following fields:
 * <pre>
 *      [timestamp] price size
 * </pre>
 *
 * Close ticks, high ticks, low ticks and open ticks contain the following fields:
 * <pre>
 *      [timestamp] price
 * </pre>
 *
 * Open interest and volume ticks contain the following fields:
 * <pre>
 *      [timestamp] size
 * </pre>
 *
 * Market depth ticks contain the following fields:
 * <pre>
 *      [timestamp] side/operation/position price size marketmaker
 * </pre>
 *
 * Market depth reset ticks contain the following fields:
 * <pre>
 *      [timestamp]
 * </pre>
 *
 * <h3>Type byte format</h3>
 *
 * The type byte indicates the tick's type, and has some additional flags that are used to optimise
 * the encoding. Its format is:
 * <pre>
 *      Bit 7       NEGATIVE_TICKS      If set, indicates that the price for this tick is below 
 *                                      the segment's base price.
 *
 *      Bit 6       NO_TIMESTAMP        If set, indicates that this record contains no timestamp 
 *                                      field, meaning that the timestamp is the same as for the
 *                                      previous record (or is the same as the start time for 
 *                                      the segment if this is the first record)
 *
 *      Bits 4-5    SIZE_TYPE_BITS      Indicates how the size field for this record (if any) has
 *                                      been encoded. The following values are used:
 *
 *                                      BYTE_SIZE (1)       encoded as an unsigned 8-bit value
 *                                      UINT16_SIZE (2)     encoded as an unsigned little-endian
 *                                                          16-bit value
 *                                      UINT32_SIZE (3)     encoded as an unsigned little-endian
 *                                                          32-bit value
 *
 *      Bits 0-3    TICK_TYPE_BITS      The type of the tick encoded in this record. The following
 *                                      values are used:
 *
 *                                      TICKTYPE_BID (0)
 *                                      TICKTYPE_ASK (1)
 *                                      TICKTYPE_CLOSE_PRICE (2)
 *                                      TICKTYPE_HIGH_PRICE (3)
 *                                      TICKTYPE_LOW_PRICE (4)
 *                                      TICKTYPE_MARKET_DEPTH (5)
 *                                      TICKTYPE_MARKET_DEPTH_RESET (6)
 *                                      TICKTYPE_TRADE (7)
 *                                      TICKTYPE_VOLUME (8)
 *                                      TICKTYPE_OPEN_INTEREST (9)
 *                                      TICKTYPE_OPEN_PRICE (10)
 *
 *                                      Other tick types may be added in future. Note that the maximum
 *                                      value of 'Tick type' is 15, but there may be a need for more 
 *                                      tick types than this. Therefore the value 15 is reserved to
 *                                      indicate that the tick type is encoded using an extension
 *                                      mechanism. This mechanism is not currently defined.
 * </pre>
 *
 * <h3>Timestamp field format</h3>
 *
 * The timestamp field is encoded as a little-endian unsigned 16-bit integer value representing the number of 
 * milliseconds between the start of the encoding period and the time of the tick.
 *
 * <h3>Price field format</h3>
 *
 * The base price for an encoded segment is the first price value encountered during encoding.
 *
 * The price field is stored as an integer value, being the absolute value of the difference between the tick price 
 * and the base price, divided by the minimum tick size (call this value numTicks). If numticks is negative, then 
 * NEGATIVE_TICKS in the type byte is set. The absolute value of numticks (|numTicks|) is then encoded as follows:
 * <p>
 * - if |numTicks| is less than 128, then it is stored in a single byte
 * <p>
 * - otherwise, |numTicks| is stored as a big-endian 16-bit value, with bit 15 set to 1.
 * <p>
 * Note that this encoding scheme enables the decoder to detect whether the value is stored in one byte or two by
 * examining the first bit of the first byte.
 * <p>
 * Note also that this scheme limits |numticks| to a maximum of 32767. Therefore should there be more than 32767 ticks between the
 * first price encountered and any subsequent price during an encoding period, the encoding will fail. Given the 
 * very short duration of an encoding period, and the fact that no securities currently have prices that are more than
 * 32767 ticks, this has a near-zero probability of occurring.
 *
 * <h3>Size field format</h3>
 *
 * The size field is encoded as follows:
 * <p>
 * - if the value is less than 256, it is stored as an unsigned 8-bit value and SIZE_TYPE_BITS is set to BYTE_SIZE
 * <p>
 * - if the value is less than 65536, it is stored as an unsigned little-endian 16-bit value and SIZE_TYPE_BITS is 
 * set to SHORT_SIZE
 * <p>
 * - otherwise it is stored as an unsigned little-endian 32-bit value and SIZE_TYPE_BITS is set to INT_SIZE.
 *
 * <h3>Side/operation/position field format</h3>
 *
 *  The Side/operation/position field is stored in a single byte with the following format:
 * <pre>
 *      Bits 0-4    POSITION_BITS       The position in the Depth-of-Market (DOM) table that this tick relates to. This
 *                                      allows for a maximum of 64 levels in the DOM table.
 *
 *      Bits 5-6    OPERATION_BITS      Indicates what operation is to be performed on the specified DOM table entry.
 *                                      The following values are used:
 *
 *                                      DOM_INSERT (0)
 *                                      DOM_UPDATE (1)
 *                                      DOM_DELETE (2)
 *
 *      Bit 7       SIDE_BITS           Indicates which side of the DOM table this tick related to. The following
 *                                      values are used:
 *
 *                                      DOM_ASK (0)
 *                                      DOM_BID (1)
 * </pre>
 *
 * <h3>Marketmaker field format</h3>
 *
 * The marketmaker field is stored in UTF-16 format. It may be encoded either little-endian or big-endian, and must be 
 * preceded with the appropriate byte order marker (BOM) as specified in RFC 2781 para 4.3.
 */

package com.tradewright.tradebuild.tickutils;
