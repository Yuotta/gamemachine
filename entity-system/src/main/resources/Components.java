
package com.game_machine.entity_system.generated;

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;
import java.util.ArrayList;
import java.util.List;

import com.dyuproject.protostuff.GraphIOUtil;
import com.dyuproject.protostuff.Input;
import com.dyuproject.protostuff.Message;
import com.dyuproject.protostuff.Output;

import java.io.ByteArrayOutputStream;
import com.dyuproject.protostuff.JsonIOUtil;
import com.dyuproject.protostuff.LinkedBuffer;
import com.dyuproject.protostuff.ProtobufIOUtil;
import com.dyuproject.protostuff.ProtostuffIOUtil;
import com.dyuproject.protostuff.runtime.RuntimeSchema;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import com.game_machine.entity_system.Entity;
import com.game_machine.entity_system.Entities;
import com.game_machine.entity_system.Component;

import com.dyuproject.protostuff.Pipe;
import com.dyuproject.protostuff.Schema;

public final class Components extends com.game_machine.entity_system.Component implements Externalizable, Message<Components>, Schema<Components>
{

    public static Schema<Components> getSchema()
    {
        return DEFAULT_INSTANCE;
    }

    public static Components getDefaultInstance()
    {
        return DEFAULT_INSTANCE;
    }

    static final Components DEFAULT_INSTANCE = new Components();

    private List<Player> player;
    private List<PlayersAroundMe> playersAroundMe;
    private List<GameCommand> gameCommand;
    

    public Components()
    {
        
    }

	public List<Player> getPlayerList() {
		return player;
	}

	public void setPlayerList(List<Player> player) {
		this.player = player;
	}

	public Player getPlayer(int index)  {
        return player == null ? null : player.get(index);
    }

    public int getPlayerCount()  {
        return player == null ? 0 : player.size();
    }

    public void addPlayer(Player player)  {
        if(this.player == null)
            this.player = new ArrayList<Player>();
        this.player.add(player);
    }
	public List<PlayersAroundMe> getPlayersAroundMeList() {
		return playersAroundMe;
	}

	public void setPlayersAroundMeList(List<PlayersAroundMe> playersAroundMe) {
		this.playersAroundMe = playersAroundMe;
	}

	public PlayersAroundMe getPlayersAroundMe(int index)  {
        return playersAroundMe == null ? null : playersAroundMe.get(index);
    }

    public int getPlayersAroundMeCount()  {
        return playersAroundMe == null ? 0 : playersAroundMe.size();
    }

    public void addPlayersAroundMe(PlayersAroundMe playersAroundMe)  {
        if(this.playersAroundMe == null)
            this.playersAroundMe = new ArrayList<PlayersAroundMe>();
        this.playersAroundMe.add(playersAroundMe);
    }
	public List<GameCommand> getGameCommandList() {
		return gameCommand;
	}

	public void setGameCommandList(List<GameCommand> gameCommand) {
		this.gameCommand = gameCommand;
	}

	public GameCommand getGameCommand(int index)  {
        return gameCommand == null ? null : gameCommand.get(index);
    }

    public int getGameCommandCount()  {
        return gameCommand == null ? 0 : gameCommand.size();
    }

    public void addGameCommand(GameCommand gameCommand)  {
        if(this.gameCommand == null)
            this.gameCommand = new ArrayList<GameCommand>();
        this.gameCommand.add(gameCommand);
    }

  
    // java serialization

    public void readExternal(ObjectInput in) throws IOException
    {
        GraphIOUtil.mergeDelimitedFrom(in, this, this);
    }

    public void writeExternal(ObjectOutput out) throws IOException
    {
        GraphIOUtil.writeDelimitedTo(out, this, this);
    }

    // message method

    public Schema<Components> cachedSchema()
    {
        return DEFAULT_INSTANCE;
    }

    // schema methods

    public Components newMessage()
    {
        return new Components();
    }

    public Class<Components> typeClass()
    {
        return Components.class;
    }

    public String messageName()
    {
        return Components.class.getSimpleName();
    }

    public String messageFullName()
    {
        return Components.class.getName();
    }

    public boolean isInitialized(Components message)
    {
        return true;
    }

    public void mergeFrom(Input input, Components message) throws IOException
    {
        for(int number = input.readFieldNumber(this);; number = input.readFieldNumber(this))
        {
            switch(number)
            {
                case 0:
                    return;
            	case 1:
            		if(message.player == null)
                        message.player = new ArrayList<Player>();
                    message.player.add(input.mergeObject(null, Player.getSchema()));
                    break;
            	case 2:
            		if(message.playersAroundMe == null)
                        message.playersAroundMe = new ArrayList<PlayersAroundMe>();
                    message.playersAroundMe.add(input.mergeObject(null, PlayersAroundMe.getSchema()));
                    break;
            	case 3:
            		if(message.gameCommand == null)
                        message.gameCommand = new ArrayList<GameCommand>();
                    message.gameCommand.add(input.mergeObject(null, GameCommand.getSchema()));
                    break;
            
                default:
                    input.handleUnknownField(number, this);
            }   
        }
    }


    public void writeTo(Output output, Components message) throws IOException
    {
        if(message.player != null)
        {
            for(Player player : message.player)
            {
                if(player != null)
                    output.writeObject(1, player, Player.getSchema(), true);
            }
        }


        if(message.playersAroundMe != null)
        {
            for(PlayersAroundMe playersAroundMe : message.playersAroundMe)
            {
                if(playersAroundMe != null)
                    output.writeObject(2, playersAroundMe, PlayersAroundMe.getSchema(), true);
            }
        }


        if(message.gameCommand != null)
        {
            for(GameCommand gameCommand : message.gameCommand)
            {
                if(gameCommand != null)
                    output.writeObject(3, gameCommand, GameCommand.getSchema(), true);
            }
        }

    }

    public String getFieldName(int number)
    {
        switch(number)
        {
            case 1: return "player";
            case 2: return "playersAroundMe";
            case 3: return "gameCommand";
            default: return null;
        }
    }

    public int getFieldNumber(String name)
    {
        final Integer number = __fieldMap.get(name);
        return number == null ? 0 : number.intValue();
    }

    private static final java.util.HashMap<String,Integer> __fieldMap = new java.util.HashMap<String,Integer>();
    static
    {
        __fieldMap.put("player", 1);
        __fieldMap.put("playersAroundMe", 2);
        __fieldMap.put("gameCommand", 3);
    }
    
    static final Pipe.Schema<Components> PIPE_SCHEMA = new Pipe.Schema<Components>(DEFAULT_INSTANCE)
    {
        protected void transfer(Pipe pipe, Input input, Output output) throws IOException
        {
            for(int number = input.readFieldNumber(wrappedSchema);; number = input.readFieldNumber(wrappedSchema))
            {
                switch(number)
                {
                    case 0:
                        return;
                    case 1:
                        output.writeObject(number, pipe, Player.getPipeSchema(), true);
                        break;

                    case 2:
                        output.writeObject(number, pipe, PlayersAroundMe.getPipeSchema(), true);
                        break;

                    case 3:
                        output.writeObject(number, pipe, GameCommand.getPipeSchema(), true);
                        break;

                    default:
                        input.handleUnknownField(number, wrappedSchema);
                }
            }
        }
    };

    public static Pipe.Schema<Components> getPipeSchema()
    {
        return PIPE_SCHEMA;
    }

    

}
