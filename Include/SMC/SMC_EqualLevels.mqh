// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_EQUALLEVELS_MQH
#define SMC_EQUALLEVELS_MQH

#include <SMC/SMC_Types.mqh>

void SMC_UpdatePivot(PivotState &pivot,const double level,const datetime pivotTime,
                     const int pivotIndex);

void SMC_DetectEqualHighLow(const int size,int &legState,
                            PivotState &equalHigh,PivotState &equalLow,
                            const int i,const int ratesTotal,
                            const datetime &time[],const double &high[],
                            const double &low[],const double &atr[],
                            const double threshold,EqualLevelEvent &event)
{
   ZeroMemory(event);
   int candidate=i+size;
   if(candidate>=ratesTotal)
      return;
   double priorHigh=-DBL_MAX,priorLow=DBL_MAX;
   for(int j=i;j<candidate;j++)
   {
      priorHigh=MathMax(priorHigh,high[j]);
      priorLow=MathMin(priorLow,low[j]);
   }
   int nextLeg=legState;
   if(high[candidate]>priorHigh)
      nextLeg=0;
   else if(low[candidate]<priorLow)
      nextLeg=1;
   if(nextLeg==legState)
      return;

   bool pivotLow=(nextLeg-legState)==1;
   PivotState previousPivot=(pivotLow ? equalLow : equalHigh);
   double currentLevel=(pivotLow ? low[candidate] : high[candidate]);
   bool atrOk=(i<ArraySize(atr) && MathIsValidNumber(atr[i]) &&
               atr[i]<DBL_MAX);
   if(atrOk && previousPivot.initialized &&
      MathAbs(previousPivot.current-currentLevel)<threshold*atr[i])
   {
      event.valid=true;
      event.high=!pivotLow;
      event.firstTime=previousPivot.time;
      event.secondTime=time[candidate];
      event.labelTime=time[(previousPivot.index+candidate)/2];
      event.firstPrice=previousPivot.current;
      event.secondPrice=currentLevel;
   }

   if(pivotLow)
      SMC_UpdatePivot(equalLow,currentLevel,time[candidate],candidate);
   else
      SMC_UpdatePivot(equalHigh,currentLevel,time[candidate],candidate);
   legState=nextLeg;
}

#endif // SMC_EQUALLEVELS_MQH
