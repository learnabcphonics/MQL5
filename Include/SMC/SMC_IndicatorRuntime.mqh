// Indicator-level adapters joining inputs/state to SMC domain and drawing modules.
// Included by SMC.mq5 after its inputs, globals, and SMC_Draw.mqh.
#ifndef SMC_INDICATOR_RUNTIME_MQH
#define SMC_INDICATOR_RUNTIME_MQH

void ConfigureDrawing()
{
   DrawConfig.objectPrefix=ObjectPrefix;
   DrawConfig.symbol=_Symbol;
   DrawConfig.chartTimeframe=_Period;
   DrawConfig.mode=DisplayMode;
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

void SMC_KeepHistoricalChartView()
{
   long autoScroll=0;
   long firstVisibleBar=0;
   long visibleBars=0;
   if(!ChartGetInteger(0,CHART_AUTOSCROLL,0,autoScroll) ||
      !ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR,0,firstVisibleBar) ||
      !ChartGetInteger(0,CHART_VISIBLE_BARS,0,visibleBars))
   {
      PrintFormat("SMC: unable to inspect chart scroll position (error=%d).",
                  GetLastError());
      return;
   }
   long rightmostVisibleBar=firstVisibleBar-visibleBars+1;
   if(autoScroll!=0 && rightmostVisibleBar>0 &&
      !ChartSetInteger(0,CHART_AUTOSCROLL,false))
      PrintFormat("SMC: unable to disable auto-scroll while viewing history (error=%d).",
                  GetLastError());
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
      SMC_PineDrawingDelete(objectName);
      SMC_PineDrawingDelete(objectName+"_Label");
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
   SMC_UpdateLiquidityFromEqualLevel(event,State.Liquidity);
   if(!event.valid)
      return;
   if(ShowEqualHighsLows)
      SMC_DrawEqualLevelEvent(DrawConfig,event,
                              event.high ? SMC_COLOR_BEARISH : SMC_COLOR_BULLISH,
                              EqualHighLowLabelSize);
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
   SMC_DrawUpdateTrailingLevels(DrawConfig,State.TrailingTop,
                                State.TrailingBottom,State.SwingBias,
                                currentTime,periodSeconds);
   SMC_DrawPremiumDiscount(DrawConfig,State.TrailingTop,
                           State.TrailingBottom,State.TrailingAnchorTime,
                           currentTime,periodSeconds);
}


#endif // SMC_INDICATOR_RUNTIME_MQH
