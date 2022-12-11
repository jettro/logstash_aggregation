# logstash_aggregation
Sample project to demo the aggregation filter of Logstash

# Files for the project
* .env - Contains the version of Logstash
* README.md - This file
* LICENSE - The Creative Commons license
* docker-compose.yml - Docker compose config file for running Logstash
* logstash_files - Auto-reloadable logstash configuration files.
* templates - Templates for the different steps for Logstash.

# Infrastructure
The sample is run using Docker, the configuration is as basic as possible. You can run the sample using the following command. Keep the trace open, we use it to read the incoming messages from the log.

```
$ docker compose up
```

Copy the contents of one of the logstash templates into the _logstash.conf_ file. Check for the following line:

```
Pipelines running {:count=>1, :running_pipelines=>[:main], :non_running_pipelines=>[]}
```

# The sample

## Step 1: Basic input output
For simplicity, we use the _http_ input. This starts an http server on the configured port (8080). If you want to change the port, notice that you also need to change the mapping in Docker. Often you can leave the port as is, and only change he port mapping if the port is taken on the host system.

For output, we just use the standard out, using rubydebug codec.

Now you can send a message to the endpoint using your favorite tool. Or use the provided bash script to send a message using curl.

```
$ ./send_step1.sh
```

### Strip what we do not need
For simplicity, and as we do not need a lot of the meta-data, we remove the fields that are not important to us. You can use the _mutate_ filter to do that. Copy the content from _step1_input_output_mutate.conf_ to the runtime configuration. On save, watch the logs, as it will reload the pipeline. WHhen finished, send the data again using the _send_step1.sh_ script, notice the differences.

## Step 2: Use aggregate filter to combine events
In the next step we add the aggregate filter, we use the action of the event to separate three different actions:
* start_session
* visit_url
* finish_session

Within each if block, we add an instance of the aggregate filter. It is important to use the exact same pattern for the field _task_id_, in our case we use _%{user_id}_ . If you use other pattern, even with the same value, the map with data will not be shared between the two instances of the aggregate.

Logstash uses a map to pass data from one event to the other. By passing the _action_ _start_session_, we create a new map using the user_id as the unique identifer. On creation, we initialize the _visited_urls_ in the map using an empty array.

The next if statement is for receiving events about the user visiting a url. Notice that we add the _visit_url_ from the vent to the map using the _<<_ sign. Now we have the _map_action_ _update_. Before we had _create_, you can also use _create_or_update_, which is the default. But in this example I like to be specific. We have the start of a session, and update it with visited urls.

In the final block, we finish the session. Notice how we read the _visited_urls_ from the map and store it in the event. We also tell Logstash to finish this task, using _end_of_task_. If you send new data, a new task should be started.

Time to copy the new config into the logstash config like you did before. This time use the contents from the template _step2_aggregate.conf_ .

Time to send some data, the _send_step2.sh_ script sends 4 events to the http input. The first to start the session, then 2 to visit urls, and finally one to finish the session. Check the output of logstash, you should see 4 events, the final one must contain the _visited_urls_.

```
$ ./send_step2.sh
```

## Step 3: Deal with timeouts
Now what if we somehow fail to send the finish event? The Logstash aggregate filter comes with a lot of options for handling timeouts. The first timeout is _timeout_, this is the timeout that starts after the first message arrives. Say we want to record a maximum of 60 minutes of a users session. We set this to 300 (5 minutes) for the example. The next timeout is the _inactivity_timeout_. With this timeout we specify the amount of time to wait after the last message was received. In our example we set this to 10 seconds.

Having the timeout is nice, now we close the task to free up memory. But we do want to keep the data that is currently in the map of the task. Therefore we tell logstash to send the data in the map as an event. You can configure this using the property _push_map_as_event_on_timeout_. 

There are some options to influence what will be in the event when sent. We add a tag, to make it easier for you to filter afterwards on tasks that got a timeout. We also add the task_id in the specified field, in our case the _user_id_.

Finally we add a code block that can interact with the map and the event. In the example we just add a message to tell what happened.

Try it out, copy the contents of the template _step3_aggregate_timeout.conf_ to the active Logstash configuration. The _send_step3.sh_ script sends the same events, only the finish event is removed.

```
$ ./send_step3.sh
```

Wait for 10-20 seconds and a new event should appear with the values from the map as well as the added data in their.

```
{
         "user_id" => "111111",
        "@version" => "1",
    "visited_urls" => [
        [0] "https://luminis.eu",
        [1] "https://luminis.eu/blogs"
    ],
         "message" => "The user left or is in a very long session.",
      "@timestamp" => 2022-12-10T12:25:32.930411Z,
            "tags" => [
        [0] "_aggregatetimeout"
    ]
}
```

# Concluding
Hope this repository can help you start exeprimenting with the aggregate filter in logstash.
