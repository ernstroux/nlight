-module(nl_srv).

-behaviour(gen_server).

-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {e1_map,
                e2_map}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    gen_server:cast(?MODULE, get_histominute),
    {ok, _TRef} = timer:apply_interval(60000, gen_server, cast, [?MODULE, get_histominute]),
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ignored, State}.

handle_cast(get_histominute, _State) ->
    {ok, App} = application:get_application(),
    Exchs = application:get_env(App, exchanges, ["Luno", "Kraken"]),
    {ok, E1, E2} = generate_outfile(Exchs),
    {noreply, #state{e1_map = E1, e2_map = E2}}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Helpers

generate_outfile([{Exch1, Curr1}, {Exch2, Curr2}]) ->
    {ok, E1M} = get_histominute(Exch1, Curr1),
    {ok, E2M} = get_histominute(Exch2, Curr2),
    E1D = maps:get(<<"Data">>, E1M),
    E2D = maps:get(<<"Data">>, E2M),
    {ok, FD} = file:open("priv/out.csv", [write, raw]),
    CreateOutLines = 
        fun(#{<<"close">> := Val1, <<"time">> := TS}, N) ->
            #{<<"close">> := Val2, <<"time">> := TS} = lists:nth(N, E2D),
            TSNow = {TS div 1000000, TS rem 1000000, 0},
            DateStr = qdate:to_string("Y/m/d H:i:s", TSNow),
            Line = lists:concat([Val1, ",", Val2*10, ",", Val1/Val2*1000, ",", DateStr, "\n"]),
            ok = file:write(FD, Line),
            N + 1
        end, 
    lists:foldl(CreateOutLines, 1, E1D),
    ok = file:close(FD),
    {ok, E1M, E2M}.

get_histominute(Exch, Curr) ->
    Url = lists:concat(["https://min-api.cryptocompare.com/data/histohour?fsym=BTC&tsym="
                        ,Curr
                        ,"&limit="
                        ,1000
                        ,"&aggregate=1&e="
                        ,Exch]),
    {ok, {{_,200,"OK"}, _, Body}} = httpc:request(get, {Url, []}, [], [{body_format, binary}]),
    {ok, jsx:decode(Body, [return_maps])}.