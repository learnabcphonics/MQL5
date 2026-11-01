// Derived from Smart Money Concepts
// Any redistribution must retain attribution and this license notice.
#ifndef SMC_ORDERBLOCK_MQH
#define SMC_ORDERBLOCK_MQH

#include <SMC/SMC_Types.mqh>
#include <SMC/SMC_State.mqh>

void SMC_StoreOrderBlock(const PivotState &pivot,const bool internal,const int bias,
                         const datetime &time[],const double &parsedHighs[],
                         const double &parsedLows[],const int ratesTotal,
                         const int currentIndex,const bool enabled,
                         OrderBlockState &orderBlocks[])
{
   if(!enabled)
      return;
   int oldest=currentIndex+1;
   int newest=pivot.index;
   if(oldest<0 || newest<oldest || newest>=ratesTotal ||
      newest>=ArraySize(parsedHighs) || newest>=ArraySize(parsedLows))
      return;
   double extreme=(bias<0 ? -DBL_MAX : DBL_MAX);
   int selected=newest;
   for(int i=newest;i>=oldest;i--)
   {
      double value=(bias<0 ? parsedHighs[i] : parsedLows[i]);
      if((bias<0 && value>extreme) || (bias>0 && value<extreme))
      {
         extreme=value;
         selected=i;
      }
   }
   OrderBlockState block;
   block.high=MathMax(parsedHighs[selected],parsedLows[selected]);
   block.low=MathMin(parsedHighs[selected],parsedLows[selected]);
   block.time=time[selected];
   block.created=time[currentIndex];
   block.bias=bias;
   block.internal=internal;
   int count=ArraySize(orderBlocks);
   if(ArrayResize(orderBlocks,count+1)!=count+1)
   {
      PrintFormat("SMC: unable to store order block (error=%d).",GetLastError());
      return;
   }
   orderBlocks[count]=block;
}

bool SMC_RemoveMitigatedOrderBlocks(const double high,const double low,
                                    const double close,const datetime barTime,
                                    const ENUM_SMC_MITIGATION mitigation,
                                    SMC_State &state,
                                    OrderBlockState &removed[],
                                    int &removedCount)
{
   removedCount=0;
   if(ArrayResize(removed,ArraySize(state.OrderBlocks))!=
      ArraySize(state.OrderBlocks))
   {
      PrintFormat("SMC: unable to allocate mitigated order block results (error=%d).",
                  GetLastError());
      return false;
   }
   double bearishSource=(mitigation==SMC_CLOSE ? close : high);
   double bullishSource=(mitigation==SMC_CLOSE ? close : low);
   int sourceCount=ArraySize(state.OrderBlocks);
   int retainedCount=0;
   for(int i=0;i<sourceCount;i++)
   {
      OrderBlockState block=state.OrderBlocks[i];
      if(block.created==barTime)
      {
         state.OrderBlocks[retainedCount]=block;
         retainedCount++;
         continue;
      }
      bool mitigated=(block.bias<0 && bearishSource>block.high) ||
                     (block.bias>0 && bullishSource<block.low);
      if(mitigated)
      {
         removed[removedCount]=block;
         removedCount++;
      }
      else
      {
         state.OrderBlocks[retainedCount]=block;
         retainedCount++;
      }
   }
   if(ArrayResize(state.OrderBlocks,retainedCount)!=retainedCount)
   {
      PrintFormat("SMC: unable to resize mitigated order block state (error=%d).",
                  GetLastError());
      return false;
   }
   return true;
}

#endif // SMC_ORDERBLOCK_MQH
