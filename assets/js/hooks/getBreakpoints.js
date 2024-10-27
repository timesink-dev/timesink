const GetBreakpoints = {
  mounted() {
    const getDeviceType = () => {
      const width = window.innerWidth;
      if (width < 640) return "mobile";
      if (width >= 640 && width < 1024) return "tablet";
      return "desktop";
    };

    this.handleResize = () => {
      const newDeviceType = getDeviceType();
      if (this.deviceType !== newDeviceType) {
        this.deviceType = newDeviceType;
        this.pushEvent("update_breakpoint", { device_type: newDeviceType });
        console.log({ deviceType: this.deviceType });
      }
    };

    this.deviceType = getDeviceType();
    window.addEventListener("resize", this.handleResize);
    this.handleResize();
  },

  destroyed() {
    window.removeEventListener("resize", this.handleResize);
  },
};

export default GetBreakpoints;
