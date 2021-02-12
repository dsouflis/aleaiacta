import React, { useEffect, useState } from 'react';

const Elm = window.Elm;

export default ({
  sz = 4,
  seed = 0,
  goalScore = 100,
  goalChains = 10,
}) => {
  const [saved, setSaved] = useState({});

  useEffect(() => {
    const flags = {
      sz,
      seed,
      goalScore,
      goalChains,
      now: Date.now(),
      names: Object.keys(saved),
    };

    const aleaiacta = Elm.Aleaiacta.init({
      node: document.getElementById("elm-area-parent").lastChild,
      flags
    });

    aleaiacta.ports.localStorageSaveState.subscribe((namedState) => {
      saved[namedState.name] = namedState.model;
      setSaved(saved);
    });

    aleaiacta.ports.localStorageLoadState.subscribe((name) => {
      const model = saved[name];
      aleaiacta.ports.localStorageLoadStateResp.send(model);
    });

    aleaiacta.ports.reload.subscribe(() => window.location.reload());
  }, []);

  return <div id="elm-area-parent"><div/></div>;
}
