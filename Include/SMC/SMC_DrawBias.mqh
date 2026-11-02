// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_DRAWBIAS_MQH
#define SMC_DRAWBIAS_MQH

#include <SMC/SMC_DrawHelpers.mqh>
#include <SMC/SMC_TimeframeSlots.mqh>

void SMC_UpdateMarketBiasLabel(const SMC_DrawConfig &config,const int swingBias,
                               const int internalBias,
                               const bool showComparisonTimeframeBias,
                               const bool showTimeframeStructure,
                               const SMC_TimeframeBiasState &timeframeBiasStates[])
{
   const int chartBiasY=40;
   const int lineSpacing=18;
   const int timeframeStartY=chartBiasY+lineSpacing;
   const int timeframeRowHeight=(showTimeframeStructure ?
                                 lineSpacing*2 : lineSpacing);
   string name=config.objectPrefix+"BIAS";
   if(!config.showMarketBias)
   {
      SMC_PineDrawingDelete(name);
      for(int i=0;i<ArraySize(timeframeBiasStates);i++)
      {
         SMC_PineDrawingDelete(config.objectPrefix+"BIAS_"+
                               SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
         SMC_PineDrawingDelete(config.objectPrefix+"BIAS_STRUCTURE_"+
                               SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
      }
      return;
   }
   color biasColor=swingBias>0 ? SMC_COLOR_BULLISH :
                   (swingBias<0 ? SMC_COLOR_BEARISH :
                                  SMC_COLOR_EQUILIBRIUM);
   SMC_PineScreenLabelSet(name,
      "SMC ["+SMC_TimeframeLabel(config.chartTimeframe)+
      "] Bias | Swing: "+SMC_BiasText(swingBias)+
      " | Internal: "+SMC_BiasText(internalBias),
      biasColor,CORNER_LEFT_UPPER,10,chartBiasY,10,true);
   if(!showComparisonTimeframeBias)
   {
      for(int i=0;i<ArraySize(timeframeBiasStates);i++)
      {
         SMC_PineDrawingDelete(config.objectPrefix+"BIAS_"+
                               SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
         SMC_PineDrawingDelete(config.objectPrefix+"BIAS_STRUCTURE_"+
                               SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
      }
      return;
   }
   int timeframeBiasRow=0;
   for(int i=0;i<ArraySize(timeframeBiasStates);i++)
   {
      if(!timeframeBiasStates[i].enabled)
      {
         if(!SMC_HasEnabledTimeframe(timeframeBiasStates,
                                     timeframeBiasStates[i].timeframe))
         {
            SMC_PineDrawingDelete(config.objectPrefix+"BIAS_"+
                                  SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
            SMC_PineDrawingDelete(config.objectPrefix+"BIAS_STRUCTURE_"+
                                  SMC_TimeframeLabel(timeframeBiasStates[i].timeframe));
         }
         continue;
      }
      if(!SMC_IsFirstEnabledTimeframeSlot(timeframeBiasStates,i))
         continue;
      string timeframeLabel=SMC_TimeframeLabel(timeframeBiasStates[i].timeframe);
      string timeframeBiasName=config.objectPrefix+"BIAS_"+timeframeLabel;
      string structureName=config.objectPrefix+"BIAS_STRUCTURE_"+
                           timeframeLabel;
      if(timeframeBiasStates[i].timeframe==config.chartTimeframe)
      {
         SMC_PineDrawingDelete(timeframeBiasName);
         SMC_PineDrawingDelete(structureName);
         continue;
      }
      string timeframeText;
      color timeframeColor=SMC_COLOR_EQUILIBRIUM;
      if(timeframeBiasStates[i].valid)
      {
         timeframeText="SMC ["+timeframeLabel+
                       "] Bias | Swing: "+
                       SMC_BiasText(timeframeBiasStates[i].swingBias)+
                       " | Internal: "+
                       SMC_BiasText(timeframeBiasStates[i].internalBias);
         timeframeColor=timeframeBiasStates[i].swingBias>0 ? SMC_COLOR_BULLISH :
                        (timeframeBiasStates[i].swingBias<0 ? SMC_COLOR_BEARISH :
                                                        SMC_COLOR_EQUILIBRIUM);
      }
      else
         timeframeText="SMC ["+timeframeLabel+
                       "] Bias | Loading closed-bar history";
      SMC_PineScreenLabelSet(timeframeBiasName,
                             timeframeText,timeframeColor,CORNER_LEFT_UPPER,
                             10,timeframeStartY+
                                timeframeBiasRow*timeframeRowHeight,10,true);
      if(showTimeframeStructure)
      {
         string structureText="SMC ["+timeframeLabel+"] Structure | ";
         if(timeframeBiasStates[i].valid)
         {
            structureText+="Swing: "+
               (timeframeBiasStates[i].swingStructureTag=="" ?
                  "UNSET" :
                  SMC_BiasText(timeframeBiasStates[i].swingStructureBias)+" "+
                  timeframeBiasStates[i].swingStructureTag);
            structureText+=" | Internal: "+
               (timeframeBiasStates[i].internalStructureTag=="" ?
                  "UNSET" :
                  SMC_BiasText(timeframeBiasStates[i].internalStructureBias)+" "+
                  timeframeBiasStates[i].internalStructureTag);
         }
         else
            structureText+="Loading closed-bar history";
         SMC_PineScreenLabelSet(structureName,structureText,timeframeColor,
                                CORNER_LEFT_UPPER,10,
                                timeframeStartY+
                                timeframeBiasRow*timeframeRowHeight+
                                lineSpacing,9,true);
      }
      else
         SMC_PineDrawingDelete(structureName);
      timeframeBiasRow++;
   }
}

#endif // SMC_DRAWBIAS_MQH
