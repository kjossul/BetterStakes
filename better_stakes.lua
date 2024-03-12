--- STEAMODDED HEADER
--- MOD_NAME: Better Stakes
--- MOD_ID: BetterStakes
--- MOD_AUTHOR: [kjossul]
--- MOD_DESCRIPTION: Rework of orange and gold stakes to, hopefully, reduce the need of constant resetting.

----------------------------------------------
------------MOD CODE -------------------------
function SMODS.INIT.BetterStakes()
    sendDebugMessage("Loaded BetterStakes~")

    -- orange stake modifications: packs with more than 3 cards have one less card instead
    -- gold stake: set probability of a card to be debuffed (doesn't get affected by "Oops! All 6s")
    local DEBUFF_CHANCE = 0.25

    -- change localization
    G.localization.descriptions.Stake.stake_orange.text = {
        "Booster Packs {C:attention}with 3 or more cards{}",
        "give {C:red}1 less card{} instead",
        "{s:0.8}Applies all previous Stakes"
    }
    G.localization.descriptions.Stake.stake_gold.text = {
        "Each card has {C:attention}25% chance{}",
        "to be {C:red}debuffed{}",
        "{s:0.8}Applies all previous Stakes"
    }
    init_localization() 

    function Game.start_run(self, args)
        args = args or {}
    
        local saveTable = args.savetext or nil
        G.SAVED_GAME = nil
    
        self:prep_stage(G.STAGES.RUN, saveTable and saveTable.STATE or G.STATES.BLIND_SELECT)
        
        G.STAGE = G.STAGES.RUN
        if saveTable then 
            check_for_unlock({type = 'continue_game'})
        end
    
        G.STATE_COMPLETE = false
        G.RESET_BLIND_STATES = true
    
        if not saveTable then ease_background_colour_blind(G.STATE, 'Small Blind')
        else ease_background_colour_blind(G.STATE, saveTable.BLIND.name:gsub("%s+", "") ~= '' and saveTable.BLIND.name or 'Small Blind') end
    
        local selected_back = saveTable and saveTable.BACK.name or (args.challenge and args.challenge.deck and args.challenge.deck.type) or (self.GAME.viewed_back and self.GAME.viewed_back.name) or self.GAME.selected_back and self.GAME.selected_back.name or 'Red Deck'
        selected_back = get_deck_from_name(selected_back)
        self.GAME = saveTable and saveTable.GAME or self:init_game_object()
        self.GAME.modifiers = self.GAME.modifiers or {}
        self.GAME.stake = args.stake or self.GAME.stake or 1
        self.GAME.STOP_USE = 0
        self.GAME.selected_back = Back(selected_back)
        self.GAME.selected_back_key = selected_back
    
        G.C.UI_CHIPS[1], G.C.UI_CHIPS[2], G.C.UI_CHIPS[3], G.C.UI_CHIPS[4] = G.C.BLUE[1], G.C.BLUE[2], G.C.BLUE[3], G.C.BLUE[4]
        G.C.UI_MULT[1], G.C.UI_MULT[2], G.C.UI_MULT[3], G.C.UI_MULT[4] = G.C.RED[1], G.C.RED[2], G.C.RED[3], G.C.RED[4]
    
        -- stake modifiers
        if not saveTable then 
            if self.GAME.stake >= 2 then 
                self.GAME.modifiers.no_blind_reward = self.GAME.modifiers.no_blind_reward or {}
                self.GAME.modifiers.no_blind_reward.Small = true
            end
            if self.GAME.stake >= 3 then self.GAME.modifiers.scaling = 2 end
            if self.GAME.stake >= 4 then self.GAME.modifiers.enable_eternals_in_shop = true end
            if self.GAME.stake >= 5 then self.GAME.starting_params.discards = self.GAME.starting_params.discards - 1 end
            if self.GAME.stake >= 6 then self.GAME.modifiers.scaling = 3 end
            if self.GAME.stake >= 7 then end
            if self.GAME.stake >= 8 then end
    
            self.GAME.selected_back:apply_to_run()
    
            if args.challenge then
                self.GAME.challenge = args.challenge.id
                self.GAME.challenge_tab = args.challenge
                local _ch = args.challenge
                if _ch.jokers then
                    for k, v in ipairs(_ch.jokers) do
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.E_MANAGER:add_event(Event({
                                    func = function()
                                        local _joker = add_joker(v.id, v.edition, k ~= 1)
                                        if v.eternal then _joker:set_eternal(true) end
                                        if v.pinned then _joker.pinned = true end
                                    return true
                                    end
                                }))
                            return true
                            end
                        }))
                    end
                end
                if _ch.consumeables then
                    for k, v in ipairs(_ch.consumeables) do
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                add_joker(v.id, nil, k ~= 1)
                            return true
                            end
                        }))
                    end
                end
                if _ch.vouchers then
                    for k, v in ipairs(_ch.vouchers) do
                        G.E_MANAGER:add_event(Event({
                            func = function()
                                G.GAME.used_vouchers[v.id] = true
                                G.GAME.starting_voucher_count = (G.GAME.starting_voucher_count or 0) + 1
                                Card.apply_to_run(nil, G.P_CENTERS[v.id])
                            return true
                            end
                        }))
                    end
                end
                if _ch.rules then
                    if _ch.rules.modifiers then
                        for k, v in ipairs(_ch.rules.modifiers) do
                            self.GAME.starting_params[v.id] = v.value
                        end
                    end
                    if _ch.rules.custom then
                        for k, v in ipairs(_ch.rules.custom) do
                            if v.id == 'no_reward' then 
                                self.GAME.modifiers.no_blind_reward = self.GAME.modifiers.no_blind_reward or {}
                                self.GAME.modifiers.no_blind_reward.Small = true
                                self.GAME.modifiers.no_blind_reward.Big = true
                                self.GAME.modifiers.no_blind_reward.Boss = true
                            elseif v.id == 'no_reward_specific' then
                                self.GAME.modifiers.no_blind_reward = self.GAME.modifiers.no_blind_reward or {}
                                self.GAME.modifiers.no_blind_reward[v.value] = true
                            elseif v.value then
                                self.GAME.modifiers[v.id] = v.value
                            elseif v.id == 'no_shop_jokers' then 
                                self.GAME.joker_rate = 0
                            else
                                self.GAME.modifiers[v.id] = true 
                            end
                        end
                    end
                end
                if _ch.restrictions then
                    if _ch.restrictions.banned_cards then
                        for k, v in ipairs(_ch.restrictions.banned_cards) do
                            G.GAME.banned_keys[v.id] = true
                            if v.ids then
                                for kk, vv in ipairs(v.ids) do
                                    G.GAME.banned_keys[vv] = true
                                end
                            end
                        end
                    end
                    if _ch.restrictions.banned_tags then
                        for k, v in ipairs(_ch.restrictions.banned_tags) do
                            G.GAME.banned_keys[v.id] = true
                        end
                    end
                end
            end
    
            self.GAME.round_resets.hands = self.GAME.starting_params.hands
            self.GAME.round_resets.discards = self.GAME.starting_params.discards
            self.GAME.round_resets.reroll_cost = self.GAME.starting_params.reroll_cost
            self.GAME.dollars = self.GAME.starting_params.dollars
            self.GAME.base_reroll_cost = self.GAME.starting_params.reroll_cost
            self.GAME.round_resets.reroll_cost = self.GAME.base_reroll_cost
            self.GAME.current_round.reroll_cost = self.GAME.base_reroll_cost
        end
    
        G.GAME.chips_text = ''
    
        if not saveTable then
            if args.seed then self.GAME.seeded = true end
            self.GAME.pseudorandom.seed = args.seed or (not (G.SETTINGS.tutorial_complete or G.SETTINGS.tutorial_progress.completed_parts['big_blind']) and "TUTORIAL") or random_string(8, G.CONTROLLER.cursor_hover.T.x*0.33411983 + G.CONTROLLER.cursor_hover.T.y*0.874146 + 0.412311010*G.CONTROLLER.cursor_hover.time)
        end
    
        for k, v in pairs(self.GAME.pseudorandom) do if v == 0 then self.GAME.pseudorandom[k] = pseudohash(k..self.GAME.pseudorandom.seed) end end
        self.GAME.pseudorandom.hashed_seed = pseudohash(self.GAME.pseudorandom.seed)
    
        G:save_settings()
    
        if not self.GAME.round_resets.blind_tags then
            self.GAME.round_resets.blind_tags = {}
        end
    
        if not saveTable then
            self.GAME.round_resets.blind_choices.Boss = get_new_boss()
            self.GAME.current_round.voucher = G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.forced_voucher or get_next_voucher_key()
            self.GAME.round_resets.blind_tags.Small = G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.forced_tags and G.SETTINGS.tutorial_progress.forced_tags[1] or get_next_tag_key()
            self.GAME.round_resets.blind_tags.Big = G.SETTINGS.tutorial_progress and G.SETTINGS.tutorial_progress.forced_tags and G.SETTINGS.tutorial_progress.forced_tags[2] or get_next_tag_key()
        else
            if self.GAME.round_resets.blind and self.GAME.round_resets.blind.key then 
                self.GAME.round_resets.blind = G.P_BLINDS[self.GAME.round_resets.blind.key]
            end
        end
        G.CONTROLLER.locks.load = true
        G.E_MANAGER:add_event(Event({
            no_delete = true,
            trigger = 'after',
            blocking = false,blockable = false,
            delay = 3.5,
            timer = 'TOTAL',
            func = function()
                G.CONTROLLER.locks.load = nil
              return true
            end
          }))
    
        if saveTable and saveTable.ACTION then
            G.E_MANAGER:add_event(Event({delay = 0.5, trigger = 'after', blocking = false,blockable = false,func = (function() 
                G.E_MANAGER:add_event(Event({func = (function() 
                    G.E_MANAGER:add_event(Event({func = (function() 
                        for k, v in pairs(G.I.CARD) do
                            if v.sort_id == saveTable.ACTION.card then
                                G.FUNCS.use_card({config = {ref_table = v}}, nil, true)
                            end
                        end
                                return true
                            end)
                        }))
                            return true
                        end)
                    }))
                    return true
                end)
            }))
        end
    
        local CAI = {
            discard_W = G.CARD_W,
            discard_H = G.CARD_H,
            deck_W = G.CARD_W*1.1,
            deck_H = 0.95*G.CARD_H,
            hand_W = 6*G.CARD_W,
            hand_H = 0.95*G.CARD_H,
            play_W = 5.3*G.CARD_W,
            play_H = 0.95*G.CARD_H,
            joker_W = 4.9*G.CARD_W,
            joker_H = 0.95*G.CARD_H,
            consumeable_W = 2.3*G.CARD_W,
            consumeable_H = 0.95*G.CARD_H
        }
    
    
        self.consumeables = CardArea(
            0, 0,
            CAI.consumeable_W,
            CAI.consumeable_H, 
            {card_limit = self.GAME.starting_params.consumable_slots, type = 'joker', highlight_limit = 1})
    
        self.jokers = CardArea(
            0, 0,
            CAI.joker_W,
            CAI.joker_H, 
            {card_limit = self.GAME.starting_params.joker_slots, type = 'joker', highlight_limit = 1})
    
        self.discard = CardArea(
            0, 0,
            CAI.discard_W,CAI.discard_H,
            {card_limit = 500, type = 'discard'})
        self.deck = CardArea(
            0, 0,
            CAI.deck_W,CAI.deck_H, 
            {card_limit = 52, type = 'deck'})
        self.hand = CardArea(
            0, 0,
            CAI.hand_W,CAI.hand_H, 
            {card_limit = self.GAME.starting_params.hand_size, type = 'hand'})
        self.play = CardArea(
            0, 0,
            CAI.play_W,CAI.play_H, 
            {card_limit = 5, type = 'play'})
        
        G.playing_cards = {}
    
        set_screen_positions()
    
        G.SPLASH_BACK = Sprite(-30, -6, G.ROOM.T.w+60, G.ROOM.T.h+12, G.ASSET_ATLAS["ui_1"], {x = 2, y = 0})
        G.SPLASH_BACK:set_alignment({
            major = G.play,
            type = 'cm',
            bond = 'Strong',
            offset = {x=0,y=0}
        })
    
        G.ARGS.spin = {
            amount = 0,
            real = 0,
            eased = 0
        }
    
        G.SPLASH_BACK:define_draw_steps({{
            shader = 'background',
            send = {
                {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL'},
                {name = 'spin_time', ref_table = G.TIMERS, ref_value = 'BACKGROUND'},
                {name = 'colour_1', ref_table = G.C.BACKGROUND, ref_value = 'C'},
                {name = 'colour_2', ref_table = G.C.BACKGROUND, ref_value = 'L'},
                {name = 'colour_3', ref_table = G.C.BACKGROUND, ref_value = 'D'},
                {name = 'contrast', ref_table = G.C.BACKGROUND, ref_value = 'contrast'},
                {name = 'spin_amount', ref_table = G.ARGS.spin, ref_value = 'amount'}
            }}})
        
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            blocking = false,
            blockable = false,
            func = (function() 
                local _dt = G.ARGS.spin.amount > G.ARGS.spin.eased and G.real_dt*2. or 0.3*G.real_dt
                local delta = G.ARGS.spin.real - G.ARGS.spin.eased
                if math.abs(delta) > _dt then delta = delta*_dt/math.abs(delta) end
                G.ARGS.spin.eased = G.ARGS.spin.eased + delta
                G.ARGS.spin.amount = _dt*(G.ARGS.spin.eased) + (1 - _dt)*G.ARGS.spin.amount
                G.TIMERS.BACKGROUND = G.TIMERS.BACKGROUND - 60*(G.ARGS.spin.eased - G.ARGS.spin.amount)*_dt
            end)
        }))
    
        if saveTable then 
            local cardAreas = saveTable.cardAreas
            for k, v in pairs(cardAreas) do
                if G[k] then G[k]:load(v)
                else
                G.DEBUG_VALUE = ''
                G['load_'..k] = v
                print("ERROR LOADING GAME: Card area '"..k.."' not instantiated before load") end
            end
    
            for k, v in pairs(G.I.CARD) do
                if v.playing_card then
                    table.insert(G.playing_cards, v)
                end
            end
            for k, v in pairs(G.I.CARDAREA) do
                v:align_cards()
                v:hard_set_cards()
            end
            table.sort(G.playing_cards, function (a, b) return a.playing_card > b.playing_card end )
        else
            local card_protos = nil
            local _de = nil
            if args.challenge and args.challenge.deck then
                _de = args.challenge.deck
            end
    
            if _de and _de.cards then
                card_protos = _de.cards
            end
    
            if not card_protos then 
                card_protos = {}
                for k, v in pairs(self.P_CARDS) do
                    local _ = nil
                    if self.GAME.starting_params.erratic_suits_and_ranks then _, k = pseudorandom_element(G.P_CARDS, pseudoseed('erratic')) end
                    local _r, _s = string.sub(k, 3, 3), string.sub(k, 1, 1)
                    local keep, _e, _d, _g = true, nil, nil, nil
                    if _de then
                        if _de.yes_ranks and not _de.yes_ranks[_r] then keep = false end
                        if _de.no_ranks and _de.no_ranks[_r] then keep = false end
                        if _de.yes_suits and not _de.yes_suits[_s] then keep = false end
                        if _de.no_suits and _de.no_suits[_s] then keep = false end
                        if _de.enhancement then _e = _de.enhancement end
                        if _de.edition then _d = _de.edition end
                        if _de.gold_seal then _g = _de.gold_seal end
                    end
    
                    if self.GAME.starting_params.no_faces and (_r == 'K' or _r == 'Q' or _r == 'J') then keep = false end
                    
                    if keep then card_protos[#card_protos+1] = {s=_s,r=_r,e=_e,d=_d,g=_g} end
                end
            end 
    
            if self.GAME.starting_params.extra_cards then 
                for k, v in pairs(self.GAME.starting_params.extra_cards) do
                    card_protos[#card_protos+1] = v
                end
            end
    
            for k, v in ipairs(card_protos) do
                card_from_control(v)
            end
    
            self.GAME.starting_deck_size = #G.playing_cards
        end
    
        delay(0.5)
    
        if not saveTable then
            G.GAME.current_round.discards_left = G.GAME.round_resets.discards
            G.GAME.current_round.hands_left = G.GAME.round_resets.hands
            self.deck:shuffle()
            self.deck:hard_set_T()
            reset_idol_card()
            reset_mail_rank()
            reset_ancient_card()
            reset_castle_card()
        end
    
        G.GAME.blind = Blind(0,0,2, 1)
        self.deck:align_cards()
        self.deck:hard_set_cards()
        
        self.HUD = UIBox{
            definition = create_UIBox_HUD(),
            config = {align=('cli'), offset = {x=-0.7,y=0},major = G.ROOM_ATTACH}
        }
        self.HUD_blind = UIBox{
            definition = create_UIBox_HUD_blind(),
            config = {major = G.HUD:get_UIE_by_ID('row_blind'), align = 'cm', offset = {x=0,y=-10}, bond = 'Weak'}
        }
        self.HUD_tags = {}
    
        G.hand_text_area = {
            chips = self.HUD:get_UIE_by_ID('hand_chips'),
            mult = self.HUD:get_UIE_by_ID('hand_mult'),
            ante = self.HUD:get_UIE_by_ID('ante_UI_count'),
            round = self.HUD:get_UIE_by_ID('round_UI_count'),
            chip_total = self.HUD:get_UIE_by_ID('hand_chip_total'),
            handname = self.HUD:get_UIE_by_ID('hand_name'),
            hand_level = self.HUD:get_UIE_by_ID('hand_level'),
            game_chips = self.HUD:get_UIE_by_ID('chip_UI_count'),
            blind_chips = self.HUD_blind:get_UIE_by_ID('HUD_blind_count'),
            blind_spacer = self.HUD:get_UIE_by_ID('blind_spacer')
        }
    
        check_and_set_high_score('most_money', G.GAME.dollars)
    
        if saveTable then 
            G.GAME.blind:load(saveTable.BLIND)
            G.GAME.tags = {}
            local tags = saveTable.tags or {}
            for k, v in ipairs(tags) do
                local _tag = Tag('tag_uncommon')
                _tag:load(v)
                add_tag(_tag)
            end
        else
            G.GAME.blind:set_blind(nil, nil, true)
        end
    
        G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
         
        self.HUD:recalculate()
    
        G.E_MANAGER:add_event(Event({
            trigger = 'immediate',
            func = (function()
                unlock_notify()
                return true
            end)
          }))
        
    end
    
    -- orange stake
    function Card.open(self)
        if self.ability.set == "Booster" then
            stop_use()
            G.STATE_COMPLETE = false 
            self.opening = true
    
            if not self.config.center.discovered then
                discover_card(self.config.center)
            end
            self.states.hover.can = false
    
            if self.ability.name:find('Arcana') then 
                G.STATE = G.STATES.TAROT_PACK
                G.GAME.pack_size = self.ability.extra
            elseif self.ability.name:find('Celestial') then
                G.STATE = G.STATES.PLANET_PACK
                G.GAME.pack_size = self.ability.extra
            elseif self.ability.name:find('Spectral') then
                G.STATE = G.STATES.SPECTRAL_PACK
                G.GAME.pack_size = self.ability.extra
            elseif self.ability.name:find('Standard') then
                G.STATE = G.STATES.STANDARD_PACK
                G.GAME.pack_size = self.ability.extra
            elseif self.ability.name:find('Buffoon') then
                G.STATE = G.STATES.BUFFOON_PACK
                G.GAME.pack_size = self.ability.extra
            end
    
            G.GAME.pack_choices = self.config.center.config.choose or 1
    
            if self.cost > 0 then 
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.2, func = function()
                    inc_career_stat('c_shop_dollars_spent', self.cost)
                    self:juice_up()
                return true end }))
                ease_dollars(-self.cost) 
           else
               delay(0.2)
           end
    
            G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.4, func = function()
                self:explode()
                local pack_cards = {}
    
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 1.3*math.sqrt(G.SETTINGS.GAMESPEED), blockable = false, blocking = false, func = function()
                    local _size = self.ability.extra
                    -- Orange stake modifier: remove one card from packs that have at least 3
                    if G.GAME.stake >= 7 and _size >= 3 then
                        _size = _size - 1
                    end
                    
                    for i = 1, _size do
                        local card = nil
                        if self.ability.name:find('Arcana') then 
                            if G.GAME.used_vouchers.v_omen_globe and pseudorandom('omen_globe') > 0.8 then
                                card = create_card("Spectral", G.pack_cards, nil, nil, true, true, nil, 'ar2')
                            else
                                card = create_card("Tarot", G.pack_cards, nil, nil, true, true, nil, 'ar1')
                            end
                        elseif self.ability.name:find('Celestial') then
                            if G.GAME.used_vouchers.v_telescope and i == 1 then
                                local _planet, _hand, _tally = nil, nil, 0
                                for k, v in ipairs(G.handlist) do
                                    if G.GAME.hands[v].visible and G.GAME.hands[v].played > _tally then
                                        _hand = v
                                        _tally = G.GAME.hands[v].played
                                    end
                                end
                                if _hand then
                                    for k, v in pairs(G.P_CENTER_POOLS.Planet) do
                                        if v.config.hand_type == _hand then
                                            _planet = v.key
                                        end
                                    end
                                end
                                card = create_card("Planet", G.pack_cards, nil, nil, true, true, _planet, 'pl1')
                            else
                                card = create_card("Planet", G.pack_cards, nil, nil, true, true, nil, 'pl1')
                            end
                        elseif self.ability.name:find('Spectral') then
                            card = create_card("Spectral", G.pack_cards, nil, nil, true, true, nil, 'spe')
                        elseif self.ability.name:find('Standard') then
                            card = create_card((pseudorandom(pseudoseed('stdset'..G.GAME.round_resets.ante)) > 0.6) and "Enhanced" or "Base", G.pack_cards, nil, nil, nil, true, nil, 'sta')
                            local edition_rate = 2
                            local edition = poll_edition('standard_edition'..G.GAME.round_resets.ante, edition_rate, true)
                            card:set_edition(edition)
                            local seal_rate = 10
                            local seal_poll = pseudorandom(pseudoseed('stdseal'..G.GAME.round_resets.ante))
                            if seal_poll > 1 - 0.02*seal_rate then
                                local seal_type = pseudorandom(pseudoseed('stdsealtype'..G.GAME.round_resets.ante))
                                if seal_type > 0.75 then card:set_seal('Red')
                                elseif seal_type > 0.5 then card:set_seal('Blue')
                                elseif seal_type > 0.25 then card:set_seal('Gold')
                                else card:set_seal('Purple')
                                end
                            end
                        elseif self.ability.name:find('Buffoon') then
                            card = create_card("Joker", G.pack_cards, nil, nil, true, true, nil, 'buf')
    
                        end
                        card.T.x = self.T.x
                        card.T.y = self.T.y
                        card:start_materialize({G.C.WHITE, G.C.WHITE}, nil, 1.5*G.SETTINGS.GAMESPEED)
                        pack_cards[i] = card
                    end
                    return true
                end}))
    
                G.E_MANAGER:add_event(Event({trigger = 'after', delay = 1.3*math.sqrt(G.SETTINGS.GAMESPEED), blockable = false, blocking = false, func = function()
                    if G.pack_cards then 
                        if G.pack_cards and G.pack_cards.VT.y < G.ROOM.T.h then 
                        for k, v in ipairs(pack_cards) do
                            G.pack_cards:emplace(v)
                        end
                        return true
                        end
                    end
                end}))
    
                for i = 1, #G.jokers.cards do
                    G.jokers.cards[i]:calculate_joker({open_booster = true, card = self})
                end
    
                if G.GAME.modifiers.inflation then 
                    G.GAME.inflation = G.GAME.inflation + 1
                    G.E_MANAGER:add_event(Event({func = function()
                      for k, v in pairs(G.I.CARD) do
                          if v.set_cost then v:set_cost() end
                      end
                      return true end }))
                end
    
            return true end }))
        end
    end
    -- gold stake
    local debuff_card_ref = Blind.debuff_card
    function Blind.debuff_card(self, card, from_blind)
        debuff_card_ref(self, card, from_blind)
        local roll = pseudorandom(pseudoseed('gold'))
        if card.playing_card and G.GAME.stake >= 8 and roll < DEBUFF_CHANCE then
            card:set_debuff(true)
        end
    end
end
----------------------------------------------
------------MOD CODE END----------------------