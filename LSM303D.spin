{
LSM303D Accelerometer/Magnetometer Driver
J.R. Leeman
kd5wxb@gmail.com
}

CON
  TEMP_OUT_L = $05
  TEMP_OUT_H = $06
  
  STATUS_M = $07
  
  OUT_X_L_M = $08
  OUT_X_H_M = $09
  OUT_Y_L_M = $0A
  OUT_Y_H_M = $0B
  OUT_Z_L_M = $0C
  OUT_Z_H_M = $0D
  
  WHO_AM_I = $0F
  
  INT_CTRL_M = $12
  INT_SRC_M = $13
  
  INT_THS_L_M = $14
  INT_THS_H_M = $15
  
  OFFSET_X_L_M = $16
  OFFSET_X_H_M = $17
  OFFSET_Y_L_M = $18
  OFFSET_Y_H_M = $19
  OFFSET_Z_L_M = $1A
  OFFSET_Z_H_M = $1B
  
  REFERENCE_X = $1C
  REFERENCE_Y = $1D
  REFERENCE_Z = $1E
  
  CTRL0 = $1F
  CTRL1 = $20
  CTRL2 = $21
  CTRL3 = $22
  CTRL4 = $23
  CTRL5 = $24
  CTRL6 = $25
  CTRL7 = $26
  
  STATUS_A = $27
  
  OUT_X_L_A = $28
  OUT_X_H_A = $29
  OUT_Y_L_A = $2A
  OUT_Y_H_A = $2B
  OUT_Z_L_A = $2C
  OUT_Z_H_A = $2D
  
  FIFO_CTRL = $2E
  
  IG_CFG1 = $30
  IG_SRC1 = $31
  IG_THS1 = $32
  IG_DUR1 = $33
  
  IG_CFG2 = $34
  IG_SRC2 = $35
  IG_THS2 = $36
  IG_DUR2 = $37
  
  CLICK_CFG = $28
  CLICK_SRC = $39
  CLICK_THS = $3A
  
  TIME_LIMIT = $3B
  TIME_LATENCY = $3C
  TIME_WINDOW = $3D
  
  ACT_THS = $3E
  ACT_DUR = $3F

VAR
    word started
    byte DevAdr

OBJ
  I2C  : "I2C SPIN driver v1.4od"

PUB start(adr, data_pin, clk_pin)
  ' Start the sensor I2C bus
  DevAdr := adr
  I2C.init(clk_pin, data_pin)
  started ~~ 'Flag that sensor startup has been completed

PUB getDevId : id
  ' Gets the device ID from the chip
  ' Should be 0x49
  id := \I2C.readByte(DevAdr, WHO_AM_I)

PUB setXMagOffset(offset) | offset_h, offset_l
  ' Sets the magnetic offset in 16-bit two's complement format.
  ' Default value is 0 
  offset_h := (offset & $FF00) >> 8
  offset_l := offset & $00FF
  \I2C.writeByte(DevAdr, OFFSET_X_H_M, offset_h)
  \I2C.writeByte(DevAdr, OFFSET_X_L_M, offset_l)
  
PUB setYMagOffset(offset) | offset_h, offset_l
  ' Sets the magnetic offset in 16-bit two's complement format.
  ' Default value is 0 
  offset_h := (offset & $FF00) >> 8
  offset_l := offset & $00FF
  \I2C.writeByte(DevAdr, OFFSET_Y_H_M, offset_h)
  \I2C.writeByte(DevAdr, OFFSET_Y_L_M, offset_l)
  
PUB setZMagOffset(offset) | offset_h, offset_l
  ' Sets the magnetic offset in 16-bit two's complement format.
  ' Default value is 0 
  offset_h := (offset & $FF00) >> 8
  offset_l := offset & $00FF
  \I2C.writeByte(DevAdr, OFFSET_Z_H_M, offset_h)
  \I2C.writeByte(DevAdr, OFFSET_Z_L_M, offset_l)

PUB setAccDataRate(rate)| sampleRateEnum, rate_config

  ' Note the slower rates are actually 3.125, 6.25, and 12.5 Hz
  sampleRateEnum := lookdown(rate:   0, 3, 6, 12, 25, 50, 100, 200, 400, 800, 1600)
  rate_config   := lookup(sampleRateEnum: $0, $1, $2, $3, $4, $5, $6, $7, $8, $9, $A)
  changeRegister(CTRL1, %1111_0000, rate_config << 4 )
 
PUB setAccScale(scale) | scaleEnum, scale_config 
  scaleEnum := lookdown(scale:   2, 4, 6, 8, 16)
  scale_config   := lookup(scaleEnum: $0, $1, $2, $3, $4)
  changeRegister(CTRL2, %0011_1000, scale_config << 3)

PUB temperatureState(state)
  ' Turns the temperature sensor on or off
  changeRegister(CTRL5, %1000_0000, state << 7)

PUB setMagResolution(resolution)
  ' Sets the magnetometer resolution (1) = high, (0) = low
  if resolution > 0
    resolution := $3
  else
    resolution := $0
  changeRegister(CTRL5, %0110_0000, resolution << 5) 

PUB setMagDataRate(rate)| sampleRateEnum, rate_config

  ' Note the slower rates are actually 3.125, 6.25, and 12.5 Hz
  ' 100 Hz setting only available for accelerometer ODR > 50 Hz or accelerometer
  ' is in power-down mode.
  sampleRateEnum := lookdown(rate:   3, 6, 12, 25, 50, 100)
  rate_config   := lookup(sampleRateEnum: $0, $1, $2, $3, $4, $5, $6)
  changeRegister(CTRL1, %0001_1100, rate_config << 2 )
 
PUB setMagScale(scale) | scaleEnum, scale_config 
  scaleEnum := lookdown(scale:   2, 4, 8, 12)
  scale_config   := lookup(scaleEnum: $0, $1, $2, $3)
  changeRegister(CTRL2, %0110_0000, scale_config << 5) 

PUB setMagSensorMode(mode)
  ' 0 = Continuous-conversion mode
  ' 1 = Single-conversion mode
  ' 2 = Power-down mode
  ' 3 = Power-down mode
  ' Default is 2 (power-down)
  changeRegister(CTRL7, %0000_0011, mode)

PUB shutdown
  ' Shutdown the accelerometer, temperature,  and magnetometer 
  ' for lowest possible power consumption
  setMagSensorMode($2)
  setAccDataRate(0)
  temperatureState(0)
  
PUB changeRegister(register, mask, value) | data
  ' Changes part of a given register with the given
  ' mask and value. Data should be same size as
  ' register.
  data := \I2C.readWordB(DevAdr, register)
  data := data & !mask
  data := data | value
  \I2C.writeWordB(DevAdr, register, data)

PUB getXAcc : xAcc
  ' Reads the x-axis acceleration. It's a 16-bit two's complement value
  ' that is then modified to return actual acceleration values
  xAcc := I2C.readByte(DevAdr, OUT_X_H_A) << 24
  xAcc |= I2C.readByte(DevAdr, OUT_X_L_A) << 16
  xAcc ~>= (16)
  ' TODO: Do calibration here
  return

PUB getYAcc : yAcc
  ' Reads the y-axis acceleration. It's a 16-bit two's complement value
  ' that is then modified to return actual acceleration values
  yAcc := I2C.readByte(DevAdr, OUT_Y_H_A) << 24
  yAcc |= I2C.readByte(DevAdr, OUT_Y_L_A) << 16
  yAcc ~>= (16)
  ' TODO: Do calibration here
  return

PUB getZAcc : zAcc
  ' Reads the z-axis acceleration. It's a 16-bit two's complement value
  ' that is then modified to return actual acceleration values
  zAcc := I2C.readByte(DevAdr, OUT_Z_H_A) << 24
  zAcc |= I2C.readByte(DevAdr, OUT_Z_L_A) << 16
  zAcc ~>= (16)
  ' TODO: Do calibration here
  return

PUB getTemperature : temp
  ' Updated for LSM303D
  temp := I2C.readByte(DevAdr, TEMP_OUT_H) << 24
  temp |= I2C.readByte(DevAdr, TEMP_OUT_L) << 16
  temp ~>= (20)
  ' Do calibration here
  return

PUB getXMag : xMag
  ' Updated for LSM303D
  xMag := I2C.readByte(DevAdr, OUT_X_H_M) << 24
  xMag |= I2C.readByte(DevAdr, OUT_X_L_M) << 16
  xMag ~>= (16)
  return

PUB getYMag : yMag
  ' Updated for LSM303D
  yMag := I2C.readByte(DevAdr, OUT_Y_H_M) << 24
  yMag |= I2C.readByte(DevAdr, OUT_Y_L_M) << 16
  yMag ~>= (16)
  return

PUB getZMag : zMag
  ' Updated for LSM303D
  zMag := I2C.readByte(DevAdr, OUT_Z_H_M) << 24
  zMag |= I2C.readByte(DevAdr, OUT_Z_L_M) << 16
  zMag ~>= (16)
  return
    
PUB readReg(adr) : t
  t := I2C.readByte(DevAdr, adr) 

PUB writeReg(adr, data) : t
  t := I2C.writeByte(DevAdr, adr, data)

          