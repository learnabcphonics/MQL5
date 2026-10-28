// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_STATE_MQH
#define SMC_STATE_MQH

#include <SMC/SMC_Types.mqh>

struct SMC_State
{
   double ParsedHighs[];
   double ParsedLows[];
   double AtrCache[];
   double MeanRangeCache[];
   double TrueRangeCache[];

   datetime LastProcessedBar;
   int LastRatesTotal;

   PivotState SwingHigh;
   PivotState SwingLow;
   PivotState InternalHigh;
   PivotState InternalLow;
   PivotState EqualHigh;
   PivotState EqualLow;
   PivotState TrailingTop;
   PivotState TrailingBottom;
   datetime TrailingAnchorTime;
   StructureDisplayState LatestStructures[4];
   bool PresentStructuresDirty;
   int SwingBias;
   int InternalBias;
   int SwingLeg;
   int InternalLeg;
   int EqualLeg;

   OrderBlockState OrderBlocks[];
   FairValueGapState FairValueGaps[];
   double CurrentFVGThreshold;
   double CumulativeRangeClosedSum;
   datetime LastFVGUpdateBarTime;
   double LastFVGUpdateHigh;
   double LastFVGUpdateLow;
   bool FVGUpdateStateInitialized;
};

bool SMC_ResetState(SMC_State &state)
{
   if(ArrayResize(state.ParsedHighs,0)!=0 ||
      ArrayResize(state.ParsedLows,0)!=0 ||
      ArrayResize(state.AtrCache,0)!=0 ||
      ArrayResize(state.MeanRangeCache,0)!=0 ||
      ArrayResize(state.TrueRangeCache,0)!=0 ||
      ArrayResize(state.OrderBlocks,0)!=0 ||
      ArrayResize(state.FairValueGaps,0)!=0)
   {
      PrintFormat("SMC: unable to reset analysis state arrays (error=%d).",
                  GetLastError());
      return false;
   }

   ZeroMemory(state.SwingHigh);
   ZeroMemory(state.SwingLow);
   ZeroMemory(state.InternalHigh);
   ZeroMemory(state.InternalLow);
   ZeroMemory(state.EqualHigh);
   ZeroMemory(state.EqualLow);
   ZeroMemory(state.TrailingTop);
   ZeroMemory(state.TrailingBottom);
   state.TrailingAnchorTime=0;
   for(int i=0;i<ArraySize(state.LatestStructures);i++)
      ZeroMemory(state.LatestStructures[i]);
   state.PresentStructuresDirty=false;
   state.SwingBias=0;
   state.InternalBias=0;
   state.SwingLeg=0;
   state.InternalLeg=0;
   state.EqualLeg=0;
   state.CurrentFVGThreshold=0.0;
   state.CumulativeRangeClosedSum=0.0;
   state.LastProcessedBar=0;
   state.LastRatesTotal=0;
   state.LastFVGUpdateBarTime=0;
   state.LastFVGUpdateHigh=0.0;
   state.LastFVGUpdateLow=0.0;
   state.FVGUpdateStateInitialized=false;
   return true;
}

#endif // SMC_STATE_MQH
