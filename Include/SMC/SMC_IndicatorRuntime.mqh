// Indicator-level adapters joining inputs/state to SMC domain and drawing modules.
// Included by SMC.mq5 after its inputs, globals, and SMC_Draw.mqh.
#ifndef SMC_INDICATOR_RUNTIME_MQH
#define SMC_INDICATOR_RUNTIME_MQH

void ConfigureDrawing()
{
   DrawConfig.objectPrefix=ObjectPrefix;
   DrawConfig.symbol=_Symbol;
   DrawConfig.chartTimeframe=_Period;
   DrawConfig.showMarketBias=ShowMarketBias;
   DrawConfig.showInternalStructure=ShowInternalStructure;
   DrawConfig.showSwingStructure=ShowSwingStructure;
   DrawConfig.internalBullishStructure=InternalBullishStructure;
   DrawConfig.internalBearishStructure=InternalBearishStructure;
   DrawConfig.swingBullishStructure=SwingBullishStructure;
   DrawConfig.swingBearishStructure=SwingBearishStructure;
   DrawConfig.showInternalOrderBlocks=ShowInternalOrderBlocks;
   DrawConfig.showSwingOrderBlocks=ShowSwingOrderBlocks;
   DrawConfig.internalOrderBlocksToShow=InternalOrderBlocksToShow;
   DrawConfig.swingOrderBlocksToShow=SwingOrderBlocksToShow;
   DrawConfig.orderBlockExtend=OrderBlockExtend;
   DrawConfig.showSwingPoints=ShowSwingPoints;
   DrawConfig.swingLength=SwingLength;
   DrawConfig.showStrongHigh=ShowStrongWeakHighLow && ShowStrongHigh;
   DrawConfig.showWeakHigh=ShowStrongWeakHighLow && ShowWeakHigh;
   DrawConfig.showStrongLow=ShowStrongWeakHighLow && ShowStrongLow;
   DrawConfig.showWeakLow=ShowStrongWeakHighLow && ShowWeakLow;
   DrawConfig.showPremiumDiscountZones=ShowPremiumDiscountZones;
   DrawConfig.showDailyLevels=ShowDailyLevels;
   DrawConfig.showWeeklyLevels=ShowWeeklyLevels;
   DrawConfig.showMonthlyLevels=ShowMonthlyLevels;
   DrawConfig.dailyLevelsStyle=DailyLevelsStyle;
   DrawConfig.weeklyLevelsStyle=WeeklyLevelsStyle;
   DrawConfig.monthlyLevelsStyle=MonthlyLevelsStyle;
}

void RemoveMitigatedOrderBlocks(const double high,const double low,const double close,
                               const datetime barTime)
{
   OrderBlockState removed[];
   int removedCount=0;
   if(!SMC_RemoveMitigatedOrderBlocks(high,low,close,barTime,
                                      OrderBlockMitigation,State,
                                      removed,removedCount))
   {
      Print("SMC: order block mitigation analysis failed.");
      return;
   }
   for(int i=0;i<removedCount;i++)
   {
      string objectName=SMC_OrderBlockObjectName(DrawConfig,removed[i]);
      ObjectDelete(0,objectName);
      ObjectDelete(0,objectName+"_Label");
      ObjectDelete(0,objectName+"_Origin");
   }
}

void RenderStructureEvents(const StructureEvent &events[],const int eventCount)
{
   datetime rightTime=0;
   for(int i=0;i<eventCount;i++)
   {
      StructureEvent event=events[i];
      if(!SMC_IsStructureVisible(DrawConfig,event.internal,event.bullish,event.tag))
         continue;
      if(rightTime==0)
         rightTime=event.time+PeriodSeconds(_Period);
      color lineColor=(event.bullish ?
                       SMC_COLOR_BULLISH : SMC_COLOR_BEARISH);
      string id=(event.internal ? "I_" : "S_")+
                IntegerToString((int)event.time);
      SMC_DrawHorizontalStructure(DrawConfig,State.LatestStructures,
                                  State.PresentStructuresDirty,id,event.pivot,rightTime,
                                  event.tag,lineColor,event.internal,event.bullish,
                                  event.labelSize);
   }
}

void DetectEqualHighLow(const int size,int &legState,
                        PivotState &equalHigh,PivotState &equalLow,
                        const int i,const int ratesTotal,const datetime &time[],
                        const double &high[],const double &low[],const double &atr[])
{
   EqualLevelEvent event;
   SMC_DetectEqualHighLow(size,legState,equalHigh,equalLow,i,ratesTotal,time,
                          high,low,atr,EqualHighLowThreshold,event);
   if(!event.valid)
      return;
   if(ShowEqualHighsLows)
      SMC_DrawEqualLevelEvent(DrawConfig,event,
                              event.high ? SMC_COLOR_BEARISH : SMC_COLOR_BULLISH,
                              EqualHighLowLabelSize);
}

void DrawActiveFairValueGaps(const MqlRates &bars[])
{
   if(!ShowFairValueGaps || ArraySize(bars)==0)
      return;
   int gapCount=ArraySize(State.FairValueGaps);
   bool selected[];
   if(ArrayResize(selected,gapCount)!=gapCount)
   {
      PrintFormat("SMC: unable to allocate FVG display selection (error=%d).",
                  GetLastError());
      return;
   }
   for(int i=0;i<gapCount;i++)
      selected[i]=false;

   int displayCount=MathMin(MaxFairValueGapsToShow,gapCount);
   for(int rank=0;rank<displayCount;rank++)
   {
      int newest=-1;
      for(int i=0;i<gapCount;i++)
      {
         if(selected[i])
            continue;
         if(newest<0 || State.FairValueGaps[i].time>State.FairValueGaps[newest].time)
            newest=i;
      }
      if(newest>=0)
         selected[newest]=true;
   }

   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   datetime right=bars[0].time+FairValueGapExtend*periodSeconds;
   SMC_DeleteObjectsWithPrefix(DrawConfig.objectPrefix+"FVG_");
   for(int rank=0;rank<displayCount;rank++)
   {
      int oldest=-1;
      for(int i=0;i<gapCount;i++)
      {
         if(!selected[i])
            continue;
         if(oldest<0 ||
            State.FairValueGaps[i].time<State.FairValueGaps[oldest].time)
            oldest=i;
      }
      if(oldest<0)
         break;
      selected[oldest]=false;
      FairValueGapState gap=State.FairValueGaps[oldest];
      gap.right=right;
      color gapColor=(gap.bias>0 ? SMC_COLOR_BULLISH : SMC_COLOR_BEARISH);
      SMC_DrawFairValueGap(DrawConfig,gap,gapColor);
   }
}

void UpdateFairValueGapsOnTick(const datetime chartBarTime,
                               const double currentHigh,const double currentLow)
{
   if(!ShowFairValueGaps)
      return;
   if(State.FVGUpdateStateInitialized && State.LastFVGUpdateBarTime==chartBarTime &&
      State.LastFVGUpdateHigh==currentHigh && State.LastFVGUpdateLow==currentLow)
      return;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,4,bars);
   if(copied<4)
   {
      PrintFormat("SMC: unable to update FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   FairValueGapState removed[];
   int removedCount=0;
   if(!SMC_UpdateFairValueGaps(bars,chartBarTime,PeriodSeconds(_Period),
                               FairValueGapExtend,FairValueGapAutoThreshold,
                               _Point,State,
                               removed,removedCount))
   {
      Print("SMC: failed to update fair value gap analysis.");
      return;
   }
   for(int i=0;i<removedCount;i++)
      SMC_DeleteFairValueGap(DrawConfig,removed[i]);
   DrawActiveFairValueGaps(bars);
   State.LastFVGUpdateBarTime=chartBarTime;
   State.LastFVGUpdateHigh=currentHigh;
   State.LastFVGUpdateLow=currentLow;
   State.FVGUpdateStateInitialized=true;
}

bool RefreshCurrentFVGThreshold()
{
   if(!ShowFairValueGaps)
      return true;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to refresh FVG threshold for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return false;
   }
   return SMC_UpdateFVGThreshold(bars,_Point,State);
}

void DrawFVGs()
{
   if(!ShowFairValueGaps)
      return;
   MqlRates bars[];
   ArraySetAsSeries(bars,true);
   int copied=CopyRates(_Symbol,_Period,0,MaxBarsToProcess,bars);
   if(copied<3)
   {
      PrintFormat("SMC: unable to load FVG history for chart timeframe %s (bars=%d, error=%d).",
                  EnumToString(_Period),copied,GetLastError());
      return;
   }
   int periodSeconds=PeriodSeconds(_Period);
   if(periodSeconds<=0)
      periodSeconds=60;
   if(!SMC_AnalyzeHistoricalFVG(bars,FairValueGapAutoThreshold,
                                FairValueGapExtend,periodSeconds,_Point,
                                State))
   {
      Print("SMC: failed to analyze historical fair value gaps.");
      return;
   }
   DrawActiveFairValueGaps(bars);
}

void UpdateTrailingLevelsOnTick(const datetime currentTime,const double currentHigh,
                                const double currentLow,const int periodSeconds)
{
   double previousTop=State.TrailingTop.current;
   datetime previousTopTime=State.TrailingTop.time;
   double previousBottom=State.TrailingBottom.current;
   datetime previousBottomTime=State.TrailingBottom.time;
   bool hadTrailingTop=State.TrailingTop.initialized;
   bool hadTrailingBottom=State.TrailingBottom.initialized;
   SMC_UpdateTrailingLevels(true,currentTime,currentHigh,currentLow,
                            State);
   bool levelsChanged=hadTrailingTop!=State.TrailingTop.initialized ||
                      hadTrailingBottom!=State.TrailingBottom.initialized ||
                      previousTop!=State.TrailingTop.current ||
                      previousTopTime!=State.TrailingTop.time ||
                      previousBottom!=State.TrailingBottom.current ||
                      previousBottomTime!=State.TrailingBottom.time;
   if(!levelsChanged)
      return;
   SMC_DrawUpdateTrailingLevels(DrawConfig,State.TrailingTop,State.TrailingBottom,State.SwingBias,
                                State.TrailingAnchorTime,currentTime,periodSeconds);
}


#endif // SMC_INDICATOR_RUNTIME_MQH
