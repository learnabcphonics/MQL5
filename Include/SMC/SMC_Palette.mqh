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
const color SMC_COLOR_INTERNAL_BULLISH_OB=C'49,121,245';
const color SMC_COLOR_INTERNAL_BEARISH_OB=C'247,124,128';
const color SMC_COLOR_SWING_BULLISH_OB=C'24,72,204';
const color SMC_COLOR_SWING_BEARISH_OB=C'178,40,51';
const color SMC_COLOR_FVG_BULLISH=C'0,255,104';
const color SMC_COLOR_FVG_BEARISH=C'255,0,8';

#endif // SMC_PALETTE_MQH
