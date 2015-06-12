//+------------------------------------------------------------------+
//|                                                   stopLossEA.mq4 |
//|                                                   Istvan Kosztik |
//|                                https://www.kosztik.hu/stoplossea |
//+------------------------------------------------------------------+
#include <mt4gui2.mqh>

#property copyright "Istvan Kosztik"
#property link      "https://www.kosztik.hu/stoplossea"
#property version   "2.00"
#property strict
//--- input parameters
extern int    Length=10;
extern int    ATRperiod=5;
extern double Kv=3.5;

int hwnd=0;

int Button1,Button2,Button3,panel;

int Size=0,cnt,orderType,StopLevel,flipflop=0,flipflop2=0,Size_now,pipSzorzo;
string orderSymbol;
double smin,smax,slSell,slBuy,digits,haOpenPrev,haClosePrev,haOpen,haClose;

// Settings
int GUIX = 50;
int GUIY = 100;
int GUIX2 = 50;
int GUIY2 = 200;
int GUIX3 = 50;
int GUIY3 = 150;
int ButtonWidth=150;
int ButtonHeight=30;

bool robotMode=False;
bool robotModeActivated=False;
bool robotModeWasWarned=False;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   digits=MarketInfo(orderSymbol,MODE_DIGITS);

   ObjectsDeleteAll();
   hwnd=WindowHandle(Symbol(),Period());
// Lets remove all Objects from Chart before we start
   guiRemoveAll(hwnd);
// Lets build the Interface
   BuildInterface();
   return(0);
//---

  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
// Very important to cleanup and remove all gui items from chart      
   if(hwnd>0) { guiRemoveAll(hwnd);     guiCleanup(hwnd); }

  }
//+------------------------------------------------------------------+
//| tp meghat�roz�sa. Itt nem lesz konkr�t tp be�ll�tva, csak a prg figyeli                                                                  |
//+------------------------------------------------------------------+
void tpSet()
  {
   int Size2=OrdersTotal();
   for(int cnt2=0;cnt2<Size2;cnt2++)
     {
      OrderSelect(cnt2,SELECT_BY_POS,MODE_TRADES);
      int orderType2=OrderType(); // megn�zem a tipus�t, az sl be�ll�t�sa v�gett
      string orderSymbol2=OrderSymbol(); // DEvizap�r
      double haOpenPrev=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,5,1),5);
      double haClosePrev=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,6,1),5);
      double haOpen=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,5,0),5);
      double haClose=NormalizeDouble(iCustom(orderSymbol,PERIOD_M15,"Heiken_Ashi_Smoothed",0,6,0),5);

      Print(orderSymbol2,",",orderType2,": ",haOpenPrev,"/",haClosePrev);
      // most megvizsg�ljuk a jelenlegi trade-t
      if(orderType2==OP_BUY)
        {
         // ha buy, akkor �gy kell kil�pni, ha az el�z� HA gyertya m�r cs�kken� volt
         if(haOpenPrev<haClosePrev && haOpen<haClose)

           {            // az el�z� HA gyertya piros. Z�rnunk kell.
            bool res2=OrderClose(OrderTicket(),OrderLots(),Ask,3,Green);
            if(!res2)
              {
               Print(orderSymbol2,": ","Error in OrderClose. Error code=",GetLastError());
              }
            else
              {
               Print("Order modified successfully.");
              }
           }
        }
      if(orderType2==OP_SELL)
        {

         // ha sell, akkor �gy kell kil�pni, ha az el�z� HA gyertya n�vekv� volt.
         if(haOpenPrev>haClosePrev && haOpen>haClose)
           {
            // az el�z� HA gyertya z�ld. Z�rnunk kell.
            bool res2=OrderClose(OrderTicket(),OrderLots(),Bid,3,Green);
            if(!res2)
              {
               Print(orderSymbol2,": ","Error in OrderClose. Error code=",GetLastError());
              }
            else
              {
               Print("Order modified successfully.");
              }
           }
        }

     }

  }
//+------------------------------------------------------------------+
//| Expert setting stop loss based on ATR indicator                                             |
//+------------------------------------------------------------------+
void slSet()
  {
   Size=OrdersTotal();
   for(int cnt=0;cnt<Size;cnt++)
     {
      OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
      orderType=OrderType(); // megn�zem a tipus�t, az sl be�ll�t�sa v�gett
      orderSymbol=OrderSymbol(); // DEvizap�r
      StopLevel=MarketInfo(orderSymbol,MODE_STOPLEVEL)+MarketInfo(orderSymbol,MODE_SPREAD);
/*
    
         OP_BUY  0
	      OP_SELL 1
	   
	      csak ezzel a kett� �rt�kkel foglalkozom, semmilyen m�s tipussal.
    */
      if(orderType==OP_BUY)
        {

         slBuy=MathMax(iHigh(orderSymbol,PERIOD_M15,1)-Kv*iATR(orderSymbol,0,ATRperiod,1),iHigh(orderSymbol,PERIOD_M15,2)-Kv*iATR(orderSymbol,0,ATRperiod,2));
         // MathMax( smin[shift], High[shift+i] - Kv*iATR(NULL,0,ATRperiod,shift+i)); 
         // if (atrstop < StopLevel) slBuy = StopLevel

         Print("Market: ",StopLevel,", ATRsL: ",Kv,", ",iATR(orderSymbol,0,ATRperiod,1),", ",Kv*iATR(orderSymbol,0,ATRperiod,1));
         // Print (StopLevel,", ", High[1] - Kv*iATR(orderSymbol,0,ATRperiod,1));

         bool res=OrderModify(OrderTicket(),OrderOpenPrice(),slBuy,OrderTakeProfit(),0,Blue);
         if(!res)
           {
            Print(orderSymbol,": ","Error in OrderModify. Error code=",GetLastError());
           }
         else
           {
            Print("Order modified successfully.");
           }
        }

      if(orderType==OP_SELL)
        {

         slSell=MathMin(iLow(orderSymbol,PERIOD_M15,2)+Kv*iATR(orderSymbol,0,ATRperiod,2),iLow(orderSymbol,PERIOD_M15,1)+Kv*iATR(orderSymbol,0,ATRperiod,1));
         //  MathMin( smax[shift], Low[shift+i] + Kv*iATR(NULL,0,ATRperiod,shift+i));
         bool res=OrderModify(OrderTicket(),OrderOpenPrice(),slSell,OrderTakeProfit(),0,Red);
         if(!res)
           {
            Print(orderSymbol,": ","Error in OrderModify. Error code=",GetLastError());
           }
         else
           {
            Print("Order modified successfully.");
           }
        }
     }

  }
//+------------------------------------------------------------------+
//| Expert function                                             |
//+------------------------------------------------------------------+
void BuildInterface()
  {
   Button1=guiAdd(hwnd,"button",GUIX,GUIY+ButtonHeight*1+5,220,ButtonHeight,"Itt vagyok!");
   guiSetBgColor(hwnd,Button1,Red);

   Button2=guiAdd(hwnd,"button",GUIX2,GUIY2+ButtonHeight*1+5,220,ButtonHeight,"Robot! Most!");
   guiSetBgColor(hwnd,Button1,Red);

   Button3=guiAdd(hwnd,"button",GUIX3,GUIY3+ButtonHeight*1+5,220,ButtonHeight,"Ellenorz�s!");
   guiSetBgColor(hwnd,Button1,Red);
  }
//+------------------------------------------------------------------+
//| give the pips of profit                                                               |
//+------------------------------------------------------------------+
double pips()
  {

   double pips;
   OrderSelect(0,SELECT_BY_POS,MODE_TRADES);

   if(OrderType()==OP_BUY)
     {
      pips=(Bid-OrderOpenPrice())*100000;

     }

   if(OrderType()==OP_SELL)
     {
      pips=(OrderOpenPrice()-Ask)*100000;

     }

   return NormalizeDouble(pips, 15);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   int min,sec;

   min = Time[0] + PERIOD_M15*60 - CurTime();
   sec = min%60;
   min=(min-min%60)/60; // id�sz�m�t�sok, hogy pontosan tudjam mikor van 15. perc

   Size_now= OrdersTotal();
   if(Size!=Size_now) slSet();  // ha �j pozi van, akkor annak nyomban be�ll�tjuk az sl-t
                                // �gy nem kell v�rni a k�v. 15. percre. 
/*
                                    itt lesz egy probl�ma: ez az sl be�ll�t�s hiba miatt nem mindig t�rt�nik meg
                                    gondolom az sl t�l k�zel van a price-hoz, vagy az atr kalkul�lt sl
                                    nem esik j� helyre nagy mozg�s ut�n. 
                                    
                                    m�dos�tani kellene az slSet fg.-t �gy, ha valami hib�ra fut, akkor valami 
                                    alap�rtelmezettet �ll�tson be.
                                */

   if(min!=14) flipflop=0;

   if(min==14 && flipflop==0)
     { // csak minden 15. percben fut le egyszer �s kezdem�nyezi a robot m�dot
      // Ez a norm�lis, robot m�d mentes m�d :)
      flipflop=1;
      // slSet(); // m�gsem itt �ll�tom az sl-t aut�matikusan, hanem azt �tteszem a robot m�dba!
      guiSetBgColor(hwnd,Button1,Red);
      if(!robotMode) robotMode=True;

     }

   if(guiIsClicked(hwnd,Button3))
     {
      tpSet();
      //slSet();
     }

   if(guiIsClicked(hwnd,Button2))
     {
      robotMode=True;
      robotModeActivated=True;
      robotModeWasWarned= True;
     }
   if(guiIsClicked(hwnd,Button1))
     { // ha a gombra kattintok akkor a robot m�d le�ll, �s visszaugrik minden norm�l m�dra
      guiSetBgColor(hwnd,Button1,Green);
      robotMode=False;
      robotModeActivated=False;
      robotModeWasWarned= False;
      guiSetText(hwnd,Button1,"Itt vagyok!",0,"");
     }

   if(robotMode && robotModeWasWarned==False && min==12 && robotModeActivated==False)
     {
      // kiv�rok m�g 2 percet, h�tha meg lesz nyomva a gomb
      // ha nem aktiviz�l�dik a robot m�d

      robotModeWasWarned=True;
      Alert("Egy perc �s robotM�dba l�pek");

     }

   if(robotMode && min==11 && robotModeActivated==False)
     {
      // robot m�dba l�ptem

      robotModeActivated=True;

     }

   if(robotModeActivated)
     { // �s ez a robot m�d k�dja
      // itt is csin�lok egy 15 percenk�nti ellen�rz�st �s ebben a m�dban �ll�tom az SL-t.
      guiSetText(hwnd,Button1,"Akt�v robot m�d! ["+Ask+"]",0,"");

      if(min!=14) flipflop2=0;
      if(min==14 && flipflop2==0)
        { // csak minden 15. percben fut 

         flipflop2=1;

         tpSet();
         slSet();

        }

      // Robotm�dban meghat�rozom a TP-t
      // kil�p�sre a 
      // setTP

      // ill, benne lesz a +pips v�delem is. 
      // pipProtect

      // v�gigmegyek minden keresked�sen �s a pips() f�ggv�nnyel megvizsg�lom az �rt�ket
      // Ha ez el�ri a be�ll�tottat, akkor a a t�mbbe bejegyzem, hogy az a keresked�s nulla pip eset�n lez�rand�!
      // de hogy n�zzen ki a t�mb ?

     }

  }
//+------------------------------------------------------------------+
