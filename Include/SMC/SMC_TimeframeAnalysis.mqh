// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_TIMEFRAMEANALYSIS_MQH
#define SMC_TIMEFRAMEANALYSIS_MQH

#include <SMC/SMC_Config.mqh>
#include <SMC/SMC_Calculation.mqh>
#include <SMC/SMC_FVG.mqh>
#include <SMC/SMC_Structure.mqh>

bool SMC_ComputeClosedTimeframeAnalysis(
                                    const string symbol,
                                    const ENUM_TIMEFRAMES timeframe,
                                    const int maxBarsToProcess,
                                    const int swingLength,
                                    const bool internalConfluenceFilter,
                                    const ENUM_SMC_SIZE swingLabelSize,
                                    const ENUM_SMC_SIZE internalLabelSize,
                                    const ENUM_SMC_FILTER orderBlockFilter,
                                    const ENUM_SMC_MITIGATION orderBlockMitigation,
                                    const bool analyzeOrderBlocks,
                                    const bool analyzeFairValueGaps,
                                    const bool fairValueGapAutoThreshold,
                                    const int fairValueGapExtend,
                                    const double point,
                                    SMC_TimeframeBiasState &analysis)
{
   analysis.valid=false;
   analysis.swingStructureTime=0;
   analysis.swingStructureBias=0;
   analysis.swingStructureTag="";
   analysis.internalStructureTime=0;
   analysis.internalStructureBias=0;
   analysis.internalStructureTag="";
   if(ArrayResize(analysis.orderBlocks,0)!=0 ||
      ArrayResize(analysis.fairValueGaps,0)!=0)
   {
      PrintFormat("SMC: unable to reset %s analysis snapshot (error=%d).",
                  EnumToString(timeframe),GetLastError());
      return false;
   }

   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(symbol,timeframe,1,maxBarsToProcess,bars);
   int minimumBars=MathMax(swingLength,
                           SMC_DEFAULT_INTERNAL_STRUCTURE_SIZE)+3;
   if(copied<minimumBars)
   {
      PrintFormat("SMC: insufficient closed %s bars for MTF analysis (bars=%d, error=%d).",
                  EnumToString(timeframe),copied,GetLastError());
      return false;
   }
   ArraySetAsSeries(bars,true);

   datetime times[];
   double opens[],highs[],lows[],closes[];
   if(ArrayResize(times,copied)!=copied ||
      ArrayResize(opens,copied)!=copied ||
      ArrayResize(highs,copied)!=copied ||
      ArrayResize(lows,copied)!=copied ||
      ArrayResize(closes,copied)!=copied)
   {
      PrintFormat("SMC: unable to allocate %s analysis history (error=%d).",
                  EnumToString(timeframe),GetLastError());
      return false;
   }
   ArraySetAsSeries(times,true);
   ArraySetAsSeries(opens,true);
   ArraySetAsSeries(highs,true);
   ArraySetAsSeries(lows,true);
   ArraySetAsSeries(closes,true);
   for(int i=0;i<copied;i++)
   {
      times[i]=bars[i].time;
      opens[i]=bars[i].open;
      highs[i]=bars[i].high;
      lows[i]=bars[i].low;
      closes[i]=bars[i].close;
   }

   SMC_State higherState;
   if(!SMC_ResetState(higherState))
      return false;
   if(ArrayResize(higherState.AtrCache,copied)!=copied ||
      ArrayResize(higherState.MeanRangeCache,copied)!=copied ||
      ArrayResize(higherState.TrueRangeCache,copied)!=copied ||
      ArrayResize(higherState.ParsedHighs,copied)!=copied ||
      ArrayResize(higherState.ParsedLows,copied)!=copied)
   {
      PrintFormat("SMC: unable to allocate %s analysis caches (error=%d).",
                  EnumToString(timeframe),GetLastError());
      return false;
   }
   ArraySetAsSeries(higherState.AtrCache,true);
   ArraySetAsSeries(higherState.MeanRangeCache,true);
   ArraySetAsSeries(higherState.TrueRangeCache,true);
   ArraySetAsSeries(higherState.ParsedHighs,true);
   ArraySetAsSeries(higherState.ParsedLows,true);
   if(!SMC_InitializeCalculationCaches(copied,copied,highs,lows,closes,
                                       orderBlockFilter,higherState))
   {
      PrintFormat("SMC: unable to initialize %s MTF calculation caches.",
                  EnumToString(timeframe));
      return false;
   }

   int oldest=copied-1;
   int warmup=MathMax(swingLength,SMC_DEFAULT_INTERNAL_STRUCTURE_SIZE);
   for(int i=oldest-warmup-1;i>=0;i--)
   {
      StructureEvent events[2];
      int eventCount=0;
      SMC_DetectStructure(false,swingLength,i,copied,times,opens,highs,lows,
                          closes,false,swingLabelSize,higherState,
                          events,eventCount);
      SMC_StoreOrderBlocksFromStructureEvents(
         events,eventCount,times,higherState.ParsedHighs,
         higherState.ParsedLows,copied,i,analyzeOrderBlocks,
         higherState.OrderBlocks);
      for(int event=0;event<eventCount;event++)
      {
         if(events[event].internal)
         {
            analysis.internalStructureTime=events[event].time;
            analysis.internalStructureBias=events[event].bullish ? 1 : -1;
            analysis.internalStructureTag=events[event].tag;
         }
         else
         {
            analysis.swingStructureTime=events[event].time;
            analysis.swingStructureBias=events[event].bullish ? 1 : -1;
            analysis.swingStructureTag=events[event].tag;
         }
      }
      SMC_DetectStructure(true,SMC_DEFAULT_INTERNAL_STRUCTURE_SIZE,i,copied,
                          times,opens,highs,lows,closes,
                          internalConfluenceFilter,internalLabelSize,
                          higherState,events,eventCount);
      SMC_StoreOrderBlocksFromStructureEvents(
         events,eventCount,times,higherState.ParsedHighs,
         higherState.ParsedLows,copied,i,analyzeOrderBlocks,
         higherState.OrderBlocks);
      for(int event=0;event<eventCount;event++)
      {
         if(events[event].internal)
         {
            analysis.internalStructureTime=events[event].time;
            analysis.internalStructureBias=events[event].bullish ? 1 : -1;
            analysis.internalStructureTag=events[event].tag;
         }
         else
         {
            analysis.swingStructureTime=events[event].time;
            analysis.swingStructureBias=events[event].bullish ? 1 : -1;
            analysis.swingStructureTag=events[event].tag;
         }
      }
      if(analyzeOrderBlocks)
      {
         OrderBlockState removed[];
         int removedCount=0;
         if(!SMC_RemoveMitigatedOrderBlocks(
               highs[i],lows[i],closes[i],times[i],orderBlockMitigation,
               higherState,removed,removedCount))
         {
            PrintFormat("SMC: unable to update %s order blocks.",
                        EnumToString(timeframe));
            return false;
         }
      }
   }
   if(analyzeFairValueGaps)
   {
      int periodSeconds=PeriodSeconds(timeframe);
      if(periodSeconds<=0 ||
         !SMC_AnalyzeHistoricalFVG(bars,fairValueGapAutoThreshold,
                                   fairValueGapExtend,periodSeconds,point,
                                   higherState,true))
      {
         PrintFormat("SMC: unable to analyze %s fair value gaps.",
                     EnumToString(timeframe));
         return false;
      }
   }
   int orderBlockCount=ArraySize(higherState.OrderBlocks);
   if(ArrayResize(analysis.orderBlocks,orderBlockCount)!=orderBlockCount)
   {
      PrintFormat("SMC: unable to copy %s order blocks (error=%d).",
                  EnumToString(timeframe),GetLastError());
      return false;
   }
   for(int i=0;i<orderBlockCount;i++)
      analysis.orderBlocks[i]=higherState.OrderBlocks[i];
   int fairValueGapCount=ArraySize(higherState.FairValueGaps);
   if(ArrayResize(analysis.fairValueGaps,fairValueGapCount)!=fairValueGapCount)
   {
      PrintFormat("SMC: unable to copy %s fair value gaps (error=%d).",
                  EnumToString(timeframe),GetLastError());
      return false;
   }
   for(int i=0;i<fairValueGapCount;i++)
      analysis.fairValueGaps[i]=higherState.FairValueGaps[i];
   analysis.swingBias=higherState.SwingBias;
   analysis.internalBias=higherState.InternalBias;
   analysis.lastClosedBar=bars[0].time;
   analysis.valid=true;
   return true;
}

#endif // SMC_TIMEFRAMEANALYSIS_MQH
