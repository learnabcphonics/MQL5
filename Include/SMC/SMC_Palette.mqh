// Central, production-fixed Smart Money Concepts LuxAlgo palette.
#ifndef SMC_PALETTE_MQH
#define SMC_PALETTE_MQH

color SMC_RGBColor(const color value)
{
   return (color)((uint)value & 0x00FFFFFF);
}

const color SMC_COLOR_BULLISH=C'8,153,129';
const color SMC_COLOR_BEARISH=C'242,54,69';
const color SMC_COLOR_EQUILIBRIUM=C'135,139,148';
const color SMC_COLOR_LABEL=C'255,255,255';
const color SMC_COLOR_PREVIOUS_LEVEL=C'33,87,243';

#endif // SMC_PALETTE_MQH
