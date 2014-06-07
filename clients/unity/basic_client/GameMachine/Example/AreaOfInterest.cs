﻿using UnityEngine;
using System.Collections;
using GameMachine;

// This is an example of how to track objects in the game that are near you.
// The basic flow is that you send a message to the server at regular intervals with your position, and a request
// to return a message to you containing all objects within range.  This is sent as a single message.

// The grid tracking allows you to filter results based on the type of objects you are interested in.
// There are two types you can use.  'player' and 'npc'. These choices were completely arbitrary and will
// soon be changed so you can use any string you want to filter with.

// The default tracking radius is 25 points.  That and the size of the grid is configurable on the server side.  
// Note that on the server you can also instantiate multiple grids if you wish, and use them however you want.

// IMPORTANT -  If you just want to send locations between players and you do not care about if they are near you or not,
// this is still the best tool for the job.  Just increase the grid and cell size so that your cell size is roughly the same area
// as your entire world.  World grid size being much larger then your world area is fine and will do no harm.

// In the server config you can change the following values:
// world_grid_size - default 2000
// world_grid_cell_size - default 25.  This is your tracking radius

// The width of the grid in points is world_grid_size / world_grid_cell_size. 
// You can adjust these numbers any way you like just remember the following rules:
//   - world_grid_cell_size must divide evenly into world_grid_size.
//   - world_grid_size must be >= world_grid_cell_size * 3
//   - world_grid_cell_size is always your search radius.

public class AreaOfInterest : MonoBehaviour
{

    private double lastUpdate = 0;
    private double updatesPerSecond = 10;
    private double updateInterval;
    private EntityTracking entityTracking;

    void Start()
    {
	
        updateInterval = 0.60 / updatesPerSecond;

        entityTracking = ActorSystem.Instance.Find("EntityTracking") as EntityTracking;

        EntityTracking.PlayersReceived playersCallback = OnPlayersReceived;
        entityTracking.OnPlayersReceived(playersCallback);

        EntityTracking.NpcsReceived npcsCallback = OnNpcsReceived;
        entityTracking.OnNpcsReceived(npcsCallback);
    }
	
    void Update()
    {
        if (Time.time > (lastUpdate + updateInterval))
        {
            lastUpdate = Time.time;
            Vector3 position = this.gameObject.transform.position;
            entityTracking.Update(position.x, position.y, position.z, "npc");
        }
    }

    void OnPlayersReceived(object message)
    {
        Logger.Debug("Players received");
    }

    void OnNpcsReceived(object message)
    {
        Logger.Debug("Npcs received");
    }
}