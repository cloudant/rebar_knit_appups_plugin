% Licensed under the Apache License, Version 2.0 (the "License"); you may not
% use this file except in compliance with the License. You may obtain a copy of
% the License at
%
%   http://www.apache.org/licenses/LICENSE-2.0
%
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
% WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
% License for the specific language governing permissions and limitations under
% the License.

% This reimplements beam_lib:cmp_dirs/2 because it detects differences
% in abstract code even if that doesn't affect the module. This was
% most obvious when different paths to eunit.hrl would cause a module
% to be flagged as changed which leads to unnecessary upgrade
% instructions.

-module(rebar_knit_beam_lib).


-export([
    cmp_dirs/2
]).


cmp_dirs(Dir1, Dir2) ->
    Beams1 = lists:ukeysort(1, list_beams(Dir1)),
    Beams2 = lists:ukeysort(1, list_beams(Dir2)),

    Names1 = [M || {M, _} <- Beams1],
    Names2 = [M || {M, _} <- Beams2],

    Added0 = Names2 -- Names1,
    Removed0 = Names1 -- Names2,
    Changed0 = lists:usort(Names1 ++ Names2) -- (Added0 ++ Removed0),

    Removed = [element(2, lists:keyfind(M, 1, Beams1)) || M <- Removed0],
    Added = [element(2, lists:keyfind(M, 1, Beams2)) || M <- Added0],

    Changed = lists:flatmap(fun(M) ->
        {_, B1} = lists:keyfind(M, 1, Beams1),
        {_, B2} = lists:keyfind(M, 1, Beams2),

        Md51 = beam_lib:md5(B1),
        Md52 = beam_lib:md5(B2),

        if Md51 == Md52 -> []; true ->
            [{B1, B2}]
        end
    end, Changed0),

    {Removed, Added, Changed}.


list_beams(Dir) ->
    true = filelib:is_dir(Dir),
    Pattern = filename:join(Dir, "*.beam"),
    Files = filelib:wildcard(Pattern),
    Beams = [{filename:basename(F), F} || F <- Files],
    case lists:sort(Beams) == lists:ukeysort(1, Beams) of
        true ->
            Beams;
        false ->
            erlang:error({invalid_beam_list, Beams})
    end.
