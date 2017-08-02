%%%-------------------------------------------------------------------
%% @doc nlight top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(nlight_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

%% Child :: {Id,StartFunc,Restart,Shutdown,Type,Modules}
init([]) ->
		ChildSpecs = 
    [#{
        id => nl_srv,     
        type => worker, 
        start => {nl_srv, start_link, []}}
    ],
    {ok, {#{strategy => one_for_one}, ChildSpecs}}.

%%====================================================================
%% Internal functions
%%====================================================================
