context
{
  input endpoint: string;
  google_calendar_date: boolean = false;
  google_calendar_time: boolean = false;
  google_calendar_duration: boolean = false;
  google_calendar_title: boolean = false;
  first: boolean = false;
  day_of_week: string?;
  time_duration: number?;
  duration: number=0;
  duration_say: string?;
  time_hour_say: string?;
  time_hour: number?;
  title: string?;
  user_name: string?;
}

/**
Забронировать событие в Google Calendar

@param day_of_week - от"monday" до "sunday"
@param time_hour - время начаал события; [0; 24)
@param time_duration - продолжительность события в часах
@param title event - заголовок события

@returns "success" - событие успешно создано
@returns "conflict" - время события пересекается с другими событиями
@returns "error" - ошибка создания события
*/
external function google_calendar_book(
day_of_week: string,
time_hour: number,
time_duration: number,
title: string
): "success" | "conflict" | "error";

/**
Пригласить пользователя Discord в голосовой канал, в котором находится бот

@param user_name - какого пользователя пригласить

@returns "success" - приглашение успешно отправлено
@returns "error" - ошибка отправки приглашения
*/
external function discord_invite(user_name: string): "success" | "error";

start node root
{
  do
  {
    set $google_calendar_date=false;
    set $google_calendar_time=false;
    set $google_calendar_duration=false;
    set $google_calendar_title=false;
    digression disable
    {
      time_hour_say, duration, google_calendar_change
    }
    ;
    if ($first==true)
    {
      #sayText("Режим ожидания");
      digression enable
      {
        dasha_hello
      }
      ;
      wait *;
    }
    else
    {
      #connect($endpoint);
      #waitForSpeech(1500);
      #sayText("Привет, я тут");
      set $first=true;
      wait *;
    }
  }
  
  transitions
  {
    transition1: goto invite on #messageHasIntent("invite1");
  }
}

digression dasha_hello
{
  conditions
  {
    on #messageHasIntent("dasha") when confident;
  }
  do
  {
    if (#messageHasIntent("dasha") && #messageHasIntent("booking"))
    {
      goto transition2;
    }
    #sayText("Слушаю");
    wait *;
  }
  transitions
  {
    transition0: goto google_calendar_date on #messageHasIntent("booking") when confident;
    transition1: goto invite on #messageHasIntent("invite") when confident;
    transition2: goto google_calendar_date;
  }
}

node invite
{
  do
  {
    digression disable
    {
      dasha_hello
    }
    ;
    #sayText("Кого пригласить?");
    wait *;
  }
  
  transitions
  {
    transition0: goto friends on #messageHasData("user_name") when confident;
  }
}

node friends
{
  do
  {
    if(#messageGetData("user_name")[0]?.value == "владислав шеймо")
    {
      set $user_name ="Vladislav Sheimo";
    }
    if(#messageGetData("user_name")[0]?.value == "анна рахманова")
    {
      set $user_name ="anna.rakhmanova";
    }
    var result = external discord_invite(
    $user_name ?? ""
    );
    if (result == "success")
    {
      #sayText("Готово, приглашение отправила");
    }
    if (result == "error")
    {
      #sayText("У меня не получилось отправить приглашение");
    }
    digression enable
    {
      dasha_hello
    }
    ;
    goto transition0;
  }
  
  transitions
  {
    transition0: goto root;
  }
}
/*
digression dasha_hello1
{
conditions
{
on #messageHasIntent("dasha") && #messageHasIntent("booking") priority 1000;
}
do
{
if (#messageHasIntent("dasha") && #messageHasIntent("booking"))
{
goto transition2;
}
#sayText("Слушаю 1000");
set $dasha_hello = true;
wait *;
}
transitions
{
transition0: goto google_calendar_date on #messageHasIntent("booking") when confident;
transition2: goto google_calendar_date;
}
}
*/
node google_calendar_date
{
  do
  {
    digression disable
    {
      dasha_hello
    }
    ;
    digression enable
    {
      google_calendar_change
    }
    ;
    if ($google_calendar_date==false)
    {
      #sayText("На какой день недели забронировать встречу?");
      set $google_calendar_date=true;
      wait *;
    }
    else
    {
      goto google_calendar_time;
    }
  }
  
  transitions
  {
    transition0: goto google_calendar_time on #messageHasData("day_of_week") when confident;
    google_calendar_time: goto google_calendar_time;
  }
}

node google_calendar_time
{
  do
  {
    if (#messageHasData("day_of_week"))
    {
    set $day_of_week = #messageGetData("day_of_week")[0]?.value;
    }
    if ($google_calendar_time==false)
    {
      
      #sayText("Какое время начала встречи?");
      set $google_calendar_time=true;
      digression enable
      {
        time_hour_say
      }
      ;
      wait *;
    }
    else
    {
      goto google_calendar_duration;
    }
  }
    transitions
    {
      transition0: goto google_calendar_duration on #messageHasData("time_hour") when confident;
      google_calendar_duration: goto google_calendar_duration;
    }
  }
  
  node google_calendar_duration
  {
    do
    {
      if(#messageHasData("time_hour"))
      {
      var x = #messageGetData("time_hour")[0]?.value??"";
      set $time_hour=#parseInt(x);
      set $duration=#parseInt(x);
     }
      if ($google_calendar_duration==false)
      {
      #sayText("Сколько будет длиться встреча?");
      set $google_calendar_duration=true;
      digression disable
      {
        time_hour_say
      }
      ;
      digression enable
      {
        duration
      }
      ;
      wait *;
      }
      else
      {
      goto google_calendar_title;
      }
    }
    
    transitions
    {
      transition0: goto google_calendar_title on #messageHasData("time_hour") when confident;
      google_calendar_title: goto google_calendar_title;

    }
  }
  
  node google_calendar_title
  {
    do
    {
      if( #messageHasData("time_hour"))
      {
      var y = #messageGetData("time_hour")[0]?.value??"";
      set $time_duration = #parseInt(y);
      set $duration = $duration + #parseInt(y);
      }
      if( $google_calendar_title==false)
      {
      #sayText("Как мне назвать встречу?");
      set $google_calendar_title=true;
      wait *;
      }
      else
      {
      goto google_calendar_approv;
      }
    }
    
    transitions
    {
      transition0: goto google_calendar_approv on true when confident;
      google_calendar_approv: goto google_calendar_approv;
    }
    onexit
    {
      transition0: do
      {
        set $title = #getMessageText();
      }
    }
  }
  
  node google_calendar_approv
  {
    do
    {
      digression disable
      {
        duration
      }
      ;
      // тринадцать ноль ноль - чтобы работало для всех часов - готово
      // доработка с приглашением кого то на встречу - добавить доп вопрос о том, кого пригласить. Надо назвать имя человека, заранее заданное и Даша пригласит его, когда все данные собраны перед бронированием встречи Даша проговаривает все переменные встречи, в том числе имя человека, который приглашен на встречу
      // если встреча пересекается, то надо проговорить название всех встреч, с которыми есть пересечение
      
      #sayText("Давайте сверимся, я создаю событие в календаре ");
      #say("google_calendar_approv",
      {
        day_of_week: $day_of_week,
        time_hour_say: $time_hour_say,
        duration_say: $duration_say,
        title: $title
      }
      );
      wait *;
    }
    transitions
    {
      next: goto google_calendar_try on #messageHasSentiment("positive") when confident;
      next1: goto root on #messageHasSentiment("negative") when confident;
    }
  }
  
  node google_calendar_try
  {
    do
    {
      #sayText("Создаю встречу");
      
      var result = external google_calendar_book(
      $day_of_week ?? "",
      $time_hour ?? 0,
      $time_duration ?? 0,
      $title ?? ""
      );
      if (result == "success")
      {
        #sayText("Готово, встреча успешно создана");
        digression disable
        {
          google_calendar_change
        }
        ;
      }
      if (result == "conflict")
      {
        #sayText("К сожалению, на это время у вас уже есть встреча, давайте выберем другое время?");
      }
      if (result == "error")
      {
        #sayText("У меня не получилось создать встречу, попробуем еще раз?");
      }
      
      goto next;
    }
    transitions
    {
      next: goto root;
    }
  }
  
  digression google_calendar_change
  {
    conditions
    {
      on #messageHasAnyIntent(["change_title","change_time_start","change_day"]);
    }
    do
    {
      if (#messageHasIntent("change_title"))
      {
        set $google_calendar_title=false;
        goto change_title;
      }
      if (#messageHasIntent("change_time_start"))
      {
        set $google_calendar_time=false;
        goto change_time_start;
      }
      if (#messageHasIntent("change_day"))
      {
        set $google_calendar_date=false;
        goto change_day;
      }
    }
    transitions
    {
      change_title: goto google_calendar_title;
      change_time_start: goto google_calendar_time;
      change_day: goto google_calendar_date;
    }
  }
  
  preprocessor digression time_hour_say
  {
    conditions
    {
      on true priority 100000;
    }
    do
    {
      if (#messageGetData("time_hour")[0]?.value == "1") set $time_hour_say ="часу ночи";
      if (#messageGetData("time_hour")[0]?.value == "2") set $time_hour_say ="двух часов ночи";
      if (#messageGetData("time_hour")[0]?.value == "3") set $time_hour_say ="трёх часов ночи";
      if (#messageGetData("time_hour")[0]?.value == "4") set $time_hour_say ="четырех часов ночи";
      if (#messageGetData("time_hour")[0]?.value == "5") set $time_hour_say ="пяти часов утра";
      if (#messageGetData("time_hour")[0]?.value == "6") set $time_hour_say ="шести часов утра";
      if (#messageGetData("time_hour")[0]?.value == "7") set $time_hour_say ="семи часов утра";
      if (#messageGetData("time_hour")[0]?.value == "8") set $time_hour_say ="восьми часов утра";
      if (#messageGetData("time_hour")[0]?.value == "9") set $time_hour_say ="девяти часов утра";
      if (#messageGetData("time_hour")[0]?.value == "10") set $time_hour_say ="десяти часов утра";
      if (#messageGetData("time_hour")[0]?.value == "11") set $time_hour_say ="одиннадцати часов утра";
      if (#messageGetData("time_hour")[0]?.value == "12") set $time_hour_say ="двенадцати часов дня";
      if (#messageGetData("time_hour")[0]?.value == "13") set $time_hour_say ="тринадцати";
      if (#messageGetData("time_hour")[0]?.value == "14") set $time_hour_say ="четырнадцати";
      if (#messageGetData("time_hour")[0]?.value == "15") set $time_hour_say ="пятнадцати";
      if (#messageGetData("time_hour")[0]?.value == "16") set $time_hour_say ="шестнадцати";
      if (#messageGetData("time_hour")[0]?.value == "17") set $time_hour_say ="семнадцати";
      if (#messageGetData("time_hour")[0]?.value == "18") set $time_hour_say ="восемнадцати";
      if (#messageGetData("time_hour")[0]?.value == "19") set $time_hour_say ="девятнадцати";
      if (#messageGetData("time_hour")[0]?.value == "20") set $time_hour_say ="двадцати";
      if (#messageGetData("time_hour")[0]?.value == "21") set $time_hour_say ="двадцати одного";
      if (#messageGetData("time_hour")[0]?.value == "22") set $time_hour_say ="двадцати двух";
      if (#messageGetData("time_hour")[0]?.value == "23") set $time_hour_say ="двадцати трёх";
      if (#messageGetData("time_hour")[0]?.value == "0") set $time_hour_say ="полночи";
      /*  var x = #messageGetData("numberword",
      {
      value: true
      }
      )[0]?.value ?? "NaN";
      set digression.parse_number.age = #parseInt(x);*/
      return;
    }
  }
  
  preprocessor digression duration
  {
    conditions
    {
      on true priority 100000;
    }
    do
    {
      if($duration==1) set $duration_say ="часу ночи";
      if($duration==3) set $duration_say ="двух часов ночи";
      if($duration==4) set $duration_say ="трех часов ночи";
      if($duration==5) set $duration_say ="четырех часов ночи";
      if($duration==6) set $duration_say ="пяти часов ночи";
      if($duration==7) set $duration_say ="шести часов утра";
      if($duration==8) set $duration_say ="семи часов утра";
      if($duration==9) set $duration_say ="восьми часов утра";
      if($duration==10) set $duration_say ="девяти часов утра";
      if($duration==11) set $duration_say ="одиннадцати часов утра";
      if($duration==12) set $duration_say ="двенадцати часов дня";
      if($duration==13) set $duration_say ="тринадцати часов";
      if($duration==14) set $duration_say ="четырнадцати часов";
      if($duration==15) set $duration_say ="пятнадцати часов";
      if($duration==16) set $duration_say ="шестнадцати часов";
      if($duration==17) set $duration_say ="семнадцати часов";
      if($duration==18) set $duration_say ="восемнадцати часов";
      if($duration==19) set $duration_say ="девятнадцати часов";
      if($duration==20) set $duration_say ="двадцати часов";
      if($duration==21) set $duration_say ="двадцати одного часа";
      if($duration==22) set $duration_say ="двадцати двух часов";
      if($duration==23) set $duration_say ="двадцати трёх часов";
      if($duration==0) set $duration_say ="полуночи";
      return;
    }
  }
